#!/bin/bash
# lark-cli env-injection wrapper (reader side). Replaces ~/.local/bin/lark-cli; the real npm binary
# is preserved as ~/.local/bin/lark-cli.real. For each invocation it resolves the requested --profile
# to an app id, fetches that profile's CURRENT user access-token string from Bitwarden (cached, see
# CACHE_TTL), and injects it via LARKSUITE_CLI_USER_ACCESS_TOKEN + LARKSUITE_CLI_APP_ID. lark-cli then
# uses the env token directly: it never reads the keychain, never sees a refresh_token, never refreshes,
# and never deletes a credential file. Readers therefore cannot break the writer's single-use refresh
# chain and cannot trigger lark-cli's delete-on-failed-refresh. No keychain material is needed on a
# reader — only this wrapper + bws + the bws token (sops-managed).
#
# Feishu invalidates the OLD user access token the moment the writer refreshes. A cached token can
# therefore go dead mid-cache-life, so when lark-cli reports an auth/token error and the token came
# from cache, force-refetch the current token and retry once.
#
# The wrapper is SELF-DESCRIBING — machine docs stay minimal because the CLI explains itself:
#   - `auth status|list|check` run a LIVE health check (real API call per profile) and describe the
#     relay, instead of the real CLI's blanket "auth is not supported" (which consumers misread as
#     "Feishu is blocked").
#   - `auth login|logout|...` are refused with a pointer to the writer (re-login on a reader would
#     fork the writer's single-use refresh chain).
#   - `update` is refused: an npm reinstall would clobber this wrapper.
#
# SITE CONFIG LIVES OUTSIDE THIS FILE. Profile names, app ids and the writer hostname identify which
# organizations this account belongs to, and this repository is public — so they are read at runtime
# from $PROFILES_FILE / $WRITER_HOST_FILE, both delivered by sops (see home/secrets.nix). Without
# those files the wrapper still runs and degrades to a clear "configure me" error.
set -uo pipefail

REAL="$HOME/.local/bin/lark-cli.real"
BWS="$HOME/.local/bin/bws"
CFG="$HOME/.config/lark-sync"
TOKEN_FILE="$CFG/bws-token"
CACHE_DIR="$CFG/at-cache"
PROFILES_FILE="$CFG/profiles"       # "<profile> <app_id>" per line; '#' comments ignored
WRITER_HOST_FILE="$CFG/writer-host" # single line: host that refreshes tokens
CACHE_TTL=300   # seconds; perf knob only — correctness comes from the auth-error retry below

[ -x "$REAL" ] || { echo "lark-cli.real not found at $REAL" >&2; exit 127; }

# ---- site config lookups ---------------------------------------------------------------------
profile_to_appid() {
  [ -f "$PROFILES_FILE" ] || return 0
  awk -v want="$1" '!/^[[:space:]]*#/ && NF >= 2 && $1 == want { print $2; exit }' "$PROFILES_FILE"
}

# Canonical profile list: one name per distinct app id, so aliases aren't health-checked twice.
known_profiles() {
  [ -f "$PROFILES_FILE" ] || return 0
  awk '!/^[[:space:]]*#/ && NF >= 2 && !seen[$2]++ { print $1 }' "$PROFILES_FILE"
}

# Every accepted name (aliases included), pipe-joined, for error hints.
known_profiles_hint() {
  [ -f "$PROFILES_FILE" ] || { printf '<none configured>'; return; }
  awk '!/^[[:space:]]*#/ && NF >= 2 { printf "%s%s", sep, $1; sep = "|" }' "$PROFILES_FILE"
}

writer_host() {
  if [ -f "$WRITER_HOST_FILE" ]; then
    head -n1 "$WRITER_HOST_FILE" | tr -d '[:space:]'
  else
    printf 'the writer machine'
  fi
}

no_profiles_configured() {
  cat >&2 <<EOF
lark-cli relay: no profile map at $PROFILES_FILE
It is delivered by sops (secret lark/profile_map) — redeploy dotfiles to restore it.
Format is one "<profile> <app_id>" per line.
EOF
}

# ---- argument parsing ------------------------------------------------------------------------
# Parse POSITION-INDEPENDENTLY. --profile is a global flag, so it naturally gets written BEFORE the
# subcommand: `lark-cli --profile foo auth status`. Keying command detection off $1 (as this wrapper
# used to) then sees "--profile", NOT "auth", so every interception below is bypassed and `auth
# status` is handed straight to the real CLI — whose blanket "auth is not supported" message is the
# exact confusing output this wrapper exists to replace. So resolve --profile AND the real subcommand
# (the first two non-flag args) up front, and drive all detection off those instead of off $1.
profile=""
subcmd=""
subsub=""
want_profile=0
for a in "$@"; do
  if [ "$want_profile" = 1 ]; then profile="$a"; want_profile=0; continue; fi
  case "$a" in
    --profile=*) profile="${a#--profile=}" ;;
    --profile)   want_profile=1 ;;
    -*)          : ;;   # any other flag (or a flag's value) — never the subcommand
    *)
      if   [ -z "$subcmd" ]; then subcmd="$a"
      elif [ -z "$subsub" ]; then subsub="$a"
      fi
      ;;
  esac
done

# Meta commands that involve no credentials (schema lookup is offline): run the real CLI as-is.
# Bare flags like --version / --help leave subcmd empty and fall in here too. `update` is handled
# separately just below.
case "$subcmd" in
  schema|completion|help|"") exec "$REAL" "$@" ;;
esac

if [ "$subcmd" = "update" ]; then
  cat <<'EOF'
{
  "ok": false,
  "error": {
    "type": "unsupported",
    "message": "`lark-cli update` is disabled on this machine: the npm reinstall would overwrite the reader-side relay wrapper at ~/.local/bin/lark-cli.",
    "hint": "Update the npm package behind ~/.local/bin/lark-cli.real manually (npm install -g --prefix ~/.local @larksuite/cli@latest), then redeploy dotfiles to restore the wrapper."
  }
}
EOF
  exit 1
fi

# ---- token fetch -----------------------------------------------------------------------------
# fetch_token <appid> [force]
#   Prints the access token to stdout. force=1 ignores + deletes the cache and pulls fresh from
#   Bitwarden. Exit code signals the source so the caller knows whether a forced retry could help:
#     0 = served from cache (a forced refetch might recover an invalidated token)
#     3 = freshly fetched from Bitwarden (already current; no point retrying)
#     1 = nothing available
fetch_token() {
  local id="$1" force="${2:-0}" cache="$CACHE_DIR/$1" mtime age val project_id
  mkdir -p "$CACHE_DIR" 2>/dev/null
  if [ "$force" = 1 ]; then
    rm -f "$cache"
  elif [ -f "$cache" ]; then
    # Portable mtime in epoch seconds: GNU stat (Linux + nixpkgs coreutils on macOS) uses -c %Y,
    # BSD stat (bare macOS) uses -f %m. Sanitize to digits so a bad value just expires the cache
    # instead of crashing the arithmetic under `set -u`.
    mtime=$(stat -c %Y "$cache" 2>/dev/null || stat -f %m "$cache" 2>/dev/null || echo 0)
    case "$mtime" in ''|*[!0-9]*) mtime=0 ;; esac
    age=$(( $(date +%s) - mtime ))
    if [ "$age" -lt "$CACHE_TTL" ]; then cat "$cache"; return 0; fi
  fi
  [ -f "$TOKEN_FILE" ] || { [ -f "$cache" ] && { cat "$cache"; return 0; }; return 1; }
  export BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"
  project_id=$("$BWS" project list 2>/dev/null | python3 -c "import json,sys; print(next((p['id'] for p in json.load(sys.stdin) if p['name']=='lark-tokens'),''))" 2>/dev/null)
  [ -z "$project_id" ] && { [ -f "$cache" ] && { cat "$cache"; return 0; }; return 1; }
  val=$("$BWS" secret list "$project_id" 2>/dev/null | python3 -c "import json,sys; print(next((s['value'] for s in json.load(sys.stdin) if s['key']=='lark-at-$id'),''))" 2>/dev/null)
  if [ -n "$val" ]; then
    printf '%s' "$val" > "$cache.tmp" && mv "$cache.tmp" "$cache" && chmod 600 "$cache"
    printf '%s' "$val"; return 3
  fi
  [ -f "$cache" ] && { cat "$cache"; return 0; }  # stale fallback on transient bws failure
  return 1
}

# ---- auth: self-describing relay behaviour ---------------------------------------------------
# status|list|check → LIVE health check, so the answer reflects the truth; the real CLI in env-token
# mode refuses ALL auth commands with a generic message that consumers misread as "no access".
# Everything else under `auth` is interactive credential management, which must never run on a
# reader — refuse with an explanation of where credentials actually come from.
if [ "$subcmd" = "auth" ]; then
  case "${subsub:-status}" in
    status|list|check)
      targets="$(known_profiles)"
      [ -n "$profile" ] && targets="$profile"
      if [ -z "$targets" ]; then no_profiles_configured; exit 1; fi
      results=""
      overall=0
      for p in $targets; do
        id="$(profile_to_appid "$p")"
        if [ -z "$id" ]; then results="$results $p=unknown-profile"; overall=1; continue; fi
        t="$(fetch_token "$id")" || true
        if [ -z "$t" ]; then results="$results $p=no-token-in-bitwarden"; overall=1; continue; fi
        if env LARKSUITE_CLI_APP_ID="$id" LARKSUITE_CLI_USER_ACCESS_TOKEN="$t" LARKSUITE_CLI_DEFAULT_AS=user \
             "$REAL" contact +get-user >/dev/null 2>&1; then
          results="$results $p=ok"
          continue
        fi
        # token may have been invalidated by the writer's refresh mid-cache-life — refetch and retry
        t="$(fetch_token "$id" 1)" || true
        if [ -n "$t" ] && env LARKSUITE_CLI_APP_ID="$id" LARKSUITE_CLI_USER_ACCESS_TOKEN="$t" LARKSUITE_CLI_DEFAULT_AS=user \
             "$REAL" contact +get-user >/dev/null 2>&1; then
          results="$results $p=ok"
        else
          results="$results $p=token-rejected"; overall=1
        fi
      done
      python3 - "$overall" "$results" "$(writer_host)" "$(known_profiles_hint)" <<'PY'
import json, sys
ok = sys.argv[1] == "0"
profiles = dict(kv.split("=", 1) for kv in sys.argv[2].split())
writer, known = sys.argv[3], sys.argv[4]
hint = f"All data commands work normally with --profile <{known}>. "
if not ok:
    hint += (f"For failing profiles check the writer: "
             f"ssh {writer} 'tail ~/.config/lark-sync/lark-refresh.log'. ")
hint += "Never run `auth login` here — it would fork the writer's single-use refresh chain."
print(json.dumps({
    "ok": ok,
    "mode": "external-relay",
    "profiles": profiles,
    "message": (f"This machine is a token READER: user access tokens are refreshed on {writer} "
                "(launchd job local.lark-refresh) and injected per --profile from Bitwarden. "
                "This status was verified with live API calls just now."),
    "hint": hint,
}, indent=2, ensure_ascii=False))
PY
      exit "$overall"
      ;;
    *)
      python3 - "$(writer_host)" <<'PY'
import json, sys
writer = sys.argv[1]
print(json.dumps({
    "ok": False,
    "error": {
        "type": "unsupported",
        "message": ("Interactive auth management is disabled BY DESIGN on this machine: it is a "
                    f"token READER (tokens auto-refreshed on {writer}, injected from Bitwarden per "
                    "--profile). Re-authenticating here would fork the writer's single-use refresh "
                    "chain."),
        "hint": ("Feishu access is most likely fine — verify with `lark-cli auth status` (live "
                 "health check) or any data call with --profile. If tokens are genuinely dead, fix "
                 f"it on the writer: ssh {writer} 'tail ~/.config/lark-sync/lark-refresh.log'."),
    },
}, indent=2, ensure_ascii=False))
PY
      exit 1
      ;;
  esac
fi

# ---- data commands ---------------------------------------------------------------------------
# No resolvable --profile → can't pick a token to inject. This reader holds NO local credentials
# (tokens are injected per --profile from Bitwarden), so a user-auth call will fail with token_missing.
# Emit a hint to STDERR (never stdout, so JSON consumers are unaffected) so the failure isn't misread
# as "no access exists" — that mistake has bitten consumers who then try to re-login.
appid=""
[ -n "$profile" ] && appid="$(profile_to_appid "$profile")"
if [ -z "$appid" ]; then
  if [ ! -f "$PROFILES_FILE" ]; then
    no_profiles_configured
  elif [ -n "$profile" ]; then
    echo "lark-cli relay: unknown --profile '$profile' (known: $(known_profiles_hint))" >&2
  else
    echo "lark-cli relay: no --profile given — this machine injects a Bitwarden token per profile; add --profile <$(known_profiles_hint)> for user-auth calls" >&2
  fi
  exec "$REAL" "$@"
fi

TOKEN="$(fetch_token "$appid")"; from_cache=$?
if [ -z "$TOKEN" ]; then
  exec "$REAL" "$@"   # nothing usable from Bitwarden; let the real CLI try its own credentials
fi

ARGS=("$@")
OUT="$(mktemp)"; ERR="$(mktemp)"
trap 'rm -f "$OUT" "$ERR"' EXIT

run_cli() {  # $1 = access token
  env LARKSUITE_CLI_APP_ID="$appid" LARKSUITE_CLI_USER_ACCESS_TOKEN="$1" LARKSUITE_CLI_DEFAULT_AS=user \
    "$REAL" "${ARGS[@]}" >"$OUT" 2>"$ERR"
}

run_cli "$TOKEN"; rc=$?

# Retry once with a force-refetched token if the call FAILED (rc!=0) with an invalidated/expired/empty
# access-token error AND the token we used came from cache (from_cache=0). lark-cli writes errors to
# stderr, so we match $ERR only — never stdout — so success data can never trigger a (possibly
# write-duplicating) retry. Scope errors and other failures are left untouched: a fresh token would
# not help them.
if [ "$from_cache" = 0 ] && [ "$rc" -ne 0 ] \
   && grep -qiE 'invalid access token|token expir|user_access_token is empty|"code": ?(20005|99991677|99991668)' "$ERR"; then
  TOKEN="$(fetch_token "$appid" 1)"
  [ -n "$TOKEN" ] && { run_cli "$TOKEN"; rc=$?; }
fi

cat "$OUT"
cat "$ERR" >&2
exit "$rc"
