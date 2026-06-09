#!/bin/bash
# Writer side (mac-mini only): publish current ACCESS TOKEN strings to Bitwarden, keyed by app_id
# (secret name "lark-at-<app_id>"). Readers inject them via LARKSUITE_CLI_USER_ACCESS_TOKEN, so they
# never touch keychain/.enc/master.key and can never refresh (no refresh_token leaves this machine)
# — structurally preventing both the single-use-refresh chain break and lark-cli's delete-on-failure.
set -uo pipefail

BWS="$HOME/.local/bin/bws"
SUPP="$HOME/Library/Application Support/lark-cli"
MASTERKEY="$SUPP/master.key.file"
EXTRACT="$HOME/.local/bin/lark-extract-ats.py"
LOG="$HOME/.config/lark-sync/publish.log"
TOKEN_FILE="$HOME/.config/lark-sync/bws-token"
PROJECT_NAME="lark-tokens"

[ -f "$TOKEN_FILE" ] || { echo "no bws token" >&2; exit 0; }
export BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }
[ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 300 ] && tail -150 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

PROJECT_ID=$("$BWS" project list 2>/dev/null | python3 -c "import json,sys; print(next(p['id'] for p in json.load(sys.stdin) if p['name']=='$PROJECT_NAME'))" 2>/dev/null)
[ -z "$PROJECT_ID" ] && { log "ERROR: project not found"; exit 1; }

LIST=$("$BWS" secret list "$PROJECT_ID" 2>/dev/null)

"$EXTRACT" "$MASTERKEY" "$SUPP" | while read -r appid at; do
  [ -z "$appid" ] && continue
  key="lark-at-$appid"
  sid=$(echo "$LIST" | python3 -c "import json,sys; print(next((s['id'] for s in json.load(sys.stdin) if s['key']=='$key'), ''))" 2>/dev/null)
  if [ -n "$sid" ]; then
    "$BWS" secret edit "$sid" --value "$at" >/dev/null 2>&1 && log "updated $key" || log "FAIL edit $key"
  else
    "$BWS" secret create "$key" "$at" "$PROJECT_ID" >/dev/null 2>&1 && log "created $key" || log "FAIL create $key"
  fi
done
log "publish done"
