#!/bin/bash
# Pull lark-cli tokens from Bitwarden Secrets Manager (reader side).
# Runs on login/wake + periodically via launchd. Works from any network (cloud relay).
# Mechanism: the always-on writer machine (mac-mini) refreshes lark-cli tokens daily
# and uploads master.key.file + per-profile .enc blobs to Bitwarden. This script pulls
# them so a machine that was off for weeks gets valid tokens on wake.
# Bootstrap secret: BWS_ACCESS_TOKEN, deployed by sops to ~/.config/lark-sync/bws-token.
set -uo pipefail

BWS="$(command -v bws 2>/dev/null || echo "$HOME/.local/bin/bws")"
SUPP="$HOME/Library/Application Support/lark-cli"
LOG="$HOME/.config/lark-sync/pull.log"
TOKEN_FILE="$HOME/.config/lark-sync/bws-token"
PROJECT_NAME="lark-tokens"

[ -x "$BWS" ] || { echo "bws not installed" >&2; exit 0; }
[ -f "$TOKEN_FILE" ] || { echo "no bws token" >&2; exit 0; }
BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"
export BWS_ACCESS_TOKEN

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }
[ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 300 ] && tail -150 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

mkdir -p "$SUPP"

PROJECT_ID=$("$BWS" project list 2>/dev/null | python3 -c "import json,sys; print(next(p['id'] for p in json.load(sys.stdin) if p['name']=='$PROJECT_NAME'))" 2>/dev/null)
[ -z "$PROJECT_ID" ] && { log "SKIP: project not found / offline"; exit 0; }

LIST=$("$BWS" secret list "$PROJECT_ID" 2>/dev/null)
[ -z "$LIST" ] && { log "SKIP: cannot list secrets / offline"; exit 0; }

# key|filename pairs (no associative arrays — macOS bash 3.2)
PAIRS="
lark-master-key|master.key.file
lark-token-byte|cli_a9667d0236b95cb5_ou_7d68a0d2f625e4cbc2ccd35a121adfa2.enc
lark-token-personal|cli_a970941717385cee_ou_8edf2fc208fbaac1a93ca00ef11e2452.enc
lark-token-cheese|cli_a97ca79454785bd5_ou_e0853a43371a22ffe02953d9e89c9f83.enc
"

echo "$PAIRS" | while IFS='|' read -r key fname; do
  [ -z "$key" ] && continue
  sid=$(echo "$LIST" | python3 -c "import json,sys; print(next((s['id'] for s in json.load(sys.stdin) if s['key']=='$key'), ''))" 2>/dev/null)
  [ -z "$sid" ] && { log "WARN: $key not in Bitwarden"; continue; }
  val=$("$BWS" secret get "$sid" 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['value'])" 2>/dev/null)
  [ -z "$val" ] && { log "WARN: $key empty"; continue; }
  tmp="$SUPP/.$fname.tmp"
  echo "$val" | base64 -d > "$tmp" 2>/dev/null && mv "$tmp" "$SUPP/$fname" && chmod 600 "$SUPP/$fname" && log "pulled $key"
done
log "pull done"
