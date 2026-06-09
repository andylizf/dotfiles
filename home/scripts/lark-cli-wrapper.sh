#!/bin/bash
# lark-cli env-injection wrapper (reader side). Replaces ~/.local/bin/lark-cli; the real npm binary
# is preserved as ~/.local/bin/lark-cli.real. For each invocation it resolves the requested --profile
# to an app_id, fetches that profile's CURRENT user access-token string from Bitwarden (cached, see
# CACHE_TTL), and injects it via LARKSUITE_CLI_USER_ACCESS_TOKEN + LARKSUITE_CLI_APP_ID. lark-cli then
# uses the env token directly: it never reads the keychain, never sees a refresh_token, never refreshes,
# and never deletes a credential file. Readers therefore cannot break the writer's single-use refresh
# chain (defect A) and cannot trigger lark-cli's delete-on-failed-refresh (defect C). No .enc /
# master.key / keychain is needed on a reader — only this wrapper + bws + the bws-token (sops).
#
# Feishu invalidates the OLD user access-token the moment the writer refreshes (every ~30min). A
# cached token can therefore go dead mid-cache-life. So when lark-cli reports an auth/token error and
# the token we used came from cache, we force-refetch the current token from Bitwarden and retry once.
set -uo pipefail

REAL="$HOME/.local/bin/lark-cli.real"
BWS="$HOME/.local/bin/bws"
CFG="$HOME/.config/lark-sync"
TOKEN_FILE="$CFG/bws-token"
CACHE_DIR="$CFG/at-cache"
CACHE_TTL=300   # seconds; perf knob only — correctness comes from the auth-error retry below

[ -x "$REAL" ] || { echo "lark-cli.real not found at $REAL" >&2; exit 127; }

# Interactive / meta commands: never inject, never capture — run the real CLI straight through.
# `auth login` in particular drives an interactive browser/QR flow that must keep the live TTY.
case "${1:-}" in
  auth|login|completion|update|help|--version|-v|--help|-h|"") exec "$REAL" "$@" ;;
esac

# profile name -> app_id. Same app_id is shared by the mac-mini name and the MacBook name.
profile_to_appid() {
  case "$1" in
    personal)          echo "cli_a970941717385cee" ;;
    byte|bytedance)    echo "cli_a9667d0236b95cb5" ;;
    cheese)            echo "cli_a97ca79454785bd5" ;;
    *)                 echo "" ;;
  esac
}

# Extract the --profile value (supports "--profile x" and "--profile=x"); empty if absent.
profile=""
prev=""
for a in "$@"; do
  case "$a" in
    --profile=*) profile="${a#--profile=}" ;;
    *) [ "$prev" = "--profile" ] && profile="$a" ;;
  esac
  prev="$a"
done

# No profile to resolve → run the real CLI as-is (its own local credentials, if any).
appid=""
[ -n "$profile" ] && appid="$(profile_to_appid "$profile")"
if [ -z "$appid" ]; then
  exec "$REAL" "$@"
fi

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
# write-duplicating) retry. Scope errors (99991672) and other failures are left untouched: a fresh
# token would not help them.
if [ "$from_cache" = 0 ] && [ "$rc" -ne 0 ] \
   && grep -qiE 'invalid access token|token expir|user_access_token is empty|"code": ?(20005|99991677|99991668)' "$ERR"; then
  TOKEN="$(fetch_token "$appid" 1)"
  [ -n "$TOKEN" ] && { run_cli "$TOKEN"; rc=$?; }
fi

cat "$OUT"
cat "$ERR" >&2
exit "$rc"
