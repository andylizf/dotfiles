#!/bin/bash
# Writer side (mac-mini only): upload lark-cli tokens to Bitwarden Secrets Manager.
# Each user-token .enc has its refreshToken STRIPPED before upload, so readers can use the
# access token but can NEVER refresh — preventing them from breaking the single-use refresh
# chain (Feishu refresh tokens are single-use; a reader refreshing revokes the whole chain).
set -uo pipefail

BWS="$HOME/.local/bin/bws"
SUPP="$HOME/Library/Application Support/lark-cli"
LOG="$HOME/.config/lark-sync/upload.log"
STRIP="$HOME/.local/bin/lark-strip-refresh.py"
MASTERKEY="$SUPP/master.key.file"
TOKEN_FILE="$HOME/.config/lark-sync/bws-token"
PROJECT_NAME="lark-tokens"

[ -f "$TOKEN_FILE" ] || { echo "no bws token" >&2; exit 0; }
BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"
export BWS_ACCESS_TOKEN

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }
[ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 300 ] && tail -150 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

PROJECT_ID=$("$BWS" project list 2>/dev/null | python3 -c "import json,sys; print(next(p['id'] for p in json.load(sys.stdin) if p['name']=='$PROJECT_NAME'))" 2>/dev/null)
[ -z "$PROJECT_ID" ] && { log "ERROR: project not found"; exit 1; }

LIST=$("$BWS" secret list "$PROJECT_ID" 2>/dev/null)

# key|filename|strip  (strip=1 blanks refreshToken before upload; macOS bash 3.2, no assoc arrays)
PAIRS="
lark-master-key|master.key.file|0
lark-token-byte|cli_a9667d0236b95cb5_ou_7d68a0d2f625e4cbc2ccd35a121adfa2.enc|1
lark-token-personal|cli_a970941717385cee_ou_8edf2fc208fbaac1a93ca00ef11e2452.enc|1
lark-token-cheese|cli_a97ca79454785bd5_ou_e0853a43371a22ffe02953d9e89c9f83.enc|1
"

echo "$PAIRS" | while IFS='|' read -r key fname strip; do
  [ -z "$key" ] && continue
  f="$SUPP/$fname"
  [ -f "$f" ] || { log "SKIP $key: file missing"; continue; }
  if [ "$strip" = "1" ]; then
    tmp="/tmp/.stripped-$key.enc"
    if "$STRIP" "$MASTERKEY" "$f" "$tmp" 2>/dev/null; then
      val=$(base64 < "$tmp"); rm -f "$tmp"
    else
      log "FAIL strip $key — skipping (NOT uploading full token)"; continue
    fi
  else
    val=$(base64 < "$f")
  fi
  sid=$(echo "$LIST" | python3 -c "import json,sys; print(next((s['id'] for s in json.load(sys.stdin) if s['key']=='$key'), ''))" 2>/dev/null)
  if [ -n "$sid" ]; then
    "$BWS" secret edit "$sid" --value "$val" >/dev/null 2>&1 && log "updated $key$([ "$strip" = 1 ] && echo ' (stripped)')" || log "FAIL edit $key"
  else
    "$BWS" secret create "$key" "$val" "$PROJECT_ID" >/dev/null 2>&1 && log "created $key$([ "$strip" = 1 ] && echo ' (stripped)')" || log "FAIL create $key"
  fi
done
log "upload done"
