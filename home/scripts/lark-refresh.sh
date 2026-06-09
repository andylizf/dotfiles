#!/bin/bash
# Writer side (mac-mini only): keep the SOLE lark-cli refresh chain alive and publish
# refresh-stripped tokens to Bitwarden for readers. Runs every 30min via launchd.
# Uses the REAL lark-cli binary (never the pull-before-use wrapper — the writer must refresh).
set -uo pipefail

LARK_CLI="$HOME/.local/bin/lark-cli.real"
[ -x "$LARK_CLI" ] || LARK_CLI="$HOME/.local/bin/lark-cli"
LOG_FILE="$HOME/.config/lark-sync/lark-refresh.log"
PROXY="http://127.0.0.1:7897"
WEBHOOK_FILE="$HOME/.config/lark-sync/feishu-webhook"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

send_feishu() {
    [ -f "$WEBHOOK_FILE" ] || return 0
    local hook; hook="$(cat "$WEBHOOK_FILE")"
    local body="{\"msg_type\":\"text\",\"content\":{\"text\":\"$1\"}}"
    curl -sf --max-time 10 -x "$PROXY" -H "Content-Type: application/json" -d "$body" "$hook" >/dev/null 2>&1 ||
    curl -sf --max-time 10 -H "Content-Type: application/json" -d "$body" "$hook" >/dev/null 2>&1 || true
}

[ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt 500 ] && tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

failures=""
for profile in personal byte cheese; do
    output=$("$LARK_CLI" contact +get-user --profile "$profile" 2>&1)
    ok=$(echo "$output" | python3 -c "import sys,json; print(json.load(sys.stdin).get('ok',False))" 2>/dev/null || echo "False")
    if [ "$ok" = "True" ]; then
        log "OK: $profile token refreshed"
    else
        log "WARN: $profile refresh failed: $output"
        failures="$failures $profile"
    fi
done

if [ -n "$failures" ]; then
    send_feishu "[lark-cli] token issue:$failures -- may need re-login"
    log "ALERT sent for:$failures"
fi

# Publish freshly-refreshed ACCESS TOKEN strings to Bitwarden (keyed by app_id). Readers inject these
# via LARKSUITE_CLI_USER_ACCESS_TOKEN — no refresh_token ever leaves this machine.
if [ -x "$HOME/.local/bin/lark-publish-tokens.sh" ]; then
    log "publishing access tokens to Bitwarden..."
    PATH="/usr/bin:/bin:$HOME/.local/bin:$PATH" "$HOME/.local/bin/lark-publish-tokens.sh" >> "$LOG_FILE" 2>&1 || log "WARN: publish failed"
fi
