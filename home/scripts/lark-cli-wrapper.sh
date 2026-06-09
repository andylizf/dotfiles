#!/bin/bash
# lark-cli env-injection wrapper (reader side). Replaces ~/.local/bin/lark-cli; the real npm binary
# is preserved as ~/.local/bin/lark-cli.real. For each invocation it resolves the requested --profile
# to an app_id, fetches that profile's CURRENT user access-token string from Bitwarden (cached, see
# CACHE_TTL), and injects it via LARKSUITE_CLI_USER_ACCESS_TOKEN + LARKSUITE_CLI_APP_ID. lark-cli then
# uses the env token directly: it never reads the keychain, never sees a refresh_token, never refreshes,
# and never deletes a credential file. Readers therefore cannot break the writer's single-use refresh
# chain (defect A) and cannot trigger lark-cli's delete-on-failed-refresh (defect C). No .enc /
# master.key / keychain is needed on a reader — only this wrapper + bws + the bws-token (sops).
set -uo pipefail

REAL="$HOME/.local/bin/lark-cli.real"
BWS="$HOME/.local/bin/bws"
CFG="$HOME/.config/lark-sync"
TOKEN_FILE="$CFG/bws-token"
CACHE_DIR="$CFG/at-cache"
CACHE_TTL=600   # seconds; writer republishes every 30min, token lives ~2h

[ -x "$REAL" ] || { echo "lark-cli.real not found at $REAL" >&2; exit 127; }

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

# No profile to resolve (e.g. `lark-cli --version`, `auth ...`, completion) → run the real CLI as-is.
appid=""
[ -n "$profile" ] && appid="$(profile_to_appid "$profile")"
if [ -z "$appid" ]; then
  exec "$REAL" "$@"
fi

# Fetch the access token for this app_id from Bitwarden, with a short on-disk cache to avoid a bws
# round-trip on every invocation. On any failure fall back to the real CLI (its own local credentials).
fetch_token() {
  local id="$1" cache="$CACHE_DIR/$1" mtime age val project_id
  mkdir -p "$CACHE_DIR" 2>/dev/null
  if [ -f "$cache" ]; then
    # Portable mtime in epoch seconds: GNU stat (Linux + nixpkgs coreutils on macOS) uses -c %Y,
    # BSD stat (bare macOS) uses -f %m. Sanitize to digits so a bad value just expires the cache
    # instead of crashing the arithmetic under `set -u`.
    mtime=$(stat -c %Y "$cache" 2>/dev/null || stat -f %m "$cache" 2>/dev/null || echo 0)
    case "$mtime" in ''|*[!0-9]*) mtime=0 ;; esac
    age=$(( $(date +%s) - mtime ))
    if [ "$age" -lt "$CACHE_TTL" ]; then cat "$cache"; return 0; fi
  fi
  [ -f "$TOKEN_FILE" ] || { [ -f "$cache" ] && cat "$cache"; return 0; }
  export BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"
  project_id=$("$BWS" project list 2>/dev/null | python3 -c "import json,sys; print(next((p['id'] for p in json.load(sys.stdin) if p['name']=='lark-tokens'),''))" 2>/dev/null)
  [ -z "$project_id" ] && { [ -f "$cache" ] && cat "$cache"; return 0; }
  val=$("$BWS" secret list "$project_id" 2>/dev/null | python3 -c "import json,sys; print(next((s['value'] for s in json.load(sys.stdin) if s['key']=='lark-at-$id'),''))" 2>/dev/null)
  if [ -n "$val" ]; then
    printf '%s' "$val" > "$cache.tmp" && mv "$cache.tmp" "$cache" && chmod 600 "$cache"
    printf '%s' "$val"; return 0
  fi
  [ -f "$cache" ] && cat "$cache"  # stale-but-better-than-nothing on transient bws failure
}

TOKEN="$(fetch_token "$appid")"
if [ -z "$TOKEN" ]; then
  exec "$REAL" "$@"   # nothing usable from Bitwarden; let the real CLI try its own credentials
fi

exec env \
  LARKSUITE_CLI_APP_ID="$appid" \
  LARKSUITE_CLI_USER_ACCESS_TOKEN="$TOKEN" \
  LARKSUITE_CLI_DEFAULT_AS=user \
  "$REAL" "$@"
