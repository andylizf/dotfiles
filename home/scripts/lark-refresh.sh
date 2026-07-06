#!/bin/bash
# Writer side (mac-mini only): keep the SOLE lark-cli refresh chain alive and publish
# refresh-stripped tokens to Bitwarden for readers. Runs on a timer via launchd.
# Uses the REAL lark-cli binary (never the pull-before-use wrapper -- the writer must refresh).
#
# Hardening (2026-07-06) -- see MyClaw notes:
#  1. Connectivity pre-check: if Feishu is unreachable, skip the ENTIRE cycle without
#     attempting any refresh. A network outage must never be mistaken for a dead token,
#     and we must not poke lark-cli's refresh path while offline (that is what let a
#     single node blip delete the personal credential and force a manual re-login).
#  2. Per-profile retry with backoff: a transient blip is retried before we conclude anything.
#  3. Error classification: only a genuine auth/identity failure (user credential gone ->
#     lark-cli falls back to bot identity, or invalid/expired token) is treated as
#     "needs re-login". Network-ish failures stay transient and never raise that alert.
#  4. Alert de-dup via per-profile state: the Feishu "needs re-login" alert fires only on an
#     OK->terminal transition, plus a "recovered" notice on terminal->OK. No more 10-min spam.
set -uo pipefail

LARK_CLI="$HOME/.local/bin/lark-cli.real"
[ -x "$LARK_CLI" ] || LARK_CLI="$HOME/.local/bin/lark-cli"
CFG_DIR="$HOME/.config/lark-sync"
LOG_FILE="$CFG_DIR/lark-refresh.log"
STATE_DIR="$CFG_DIR/state"
PROXY="http://127.0.0.1:7897"
WEBHOOK_FILE="$CFG_DIR/feishu-webhook"
PROFILES="personal byte cheese"
PROBE_URL="https://open.feishu.cn/open-apis/authen/v1/user_info"
MAX_TRIES=3

mkdir -p "$STATE_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

send_feishu() {
    [ -f "$WEBHOOK_FILE" ] || return 0
    local hook; hook="$(cat "$WEBHOOK_FILE")"
    local body="{\"msg_type\":\"text\",\"content\":{\"text\":\"$1\"}}"
    curl -sf --max-time 10 -x "$PROXY" -H "Content-Type: application/json" -d "$body" "$hook" >/dev/null 2>&1 ||
    curl -sf --max-time 10 -H "Content-Type: application/json" -d "$body" "$hook" >/dev/null 2>&1 || true
}

# Reachable if we get ANY real HTTP status back (200/400/401...); "000" = no connectivity.
# curl goes over the same TUN path lark-cli uses, so this mirrors lark-cli's reachability.
feishu_reachable() {
    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$PROBE_URL" 2>/dev/null)
    [ -n "$code" ] && [ "$code" != "000" ]
}

# Classify a failed `contact +get-user` output -> "terminal" or "transient".
# terminal = the user credential is gone (lark-cli fell back to bot identity) or the token is
# invalid/expired: only an interactive re-login fixes it. Everything else is transient.
classify_failure() {
    echo "$1" | grep -qiE 'bot identity|invalid access token|invalid_grant|"identity"[[:space:]]*:[[:space:]]*"bot"|refresh[_ ]?token.*(expir|invalid)|token.*expired|token_invalid' \
        && echo terminal || echo transient
}

read_state()  { cat "$STATE_DIR/$1.state" 2>/dev/null || echo unknown; }
write_state() { echo "$2" > "$STATE_DIR/$1.state"; }

# --- 1. Connectivity pre-check -------------------------------------------------
if ! feishu_reachable; then
    log "SKIP cycle: Feishu unreachable (connectivity pre-check failed); credentials untouched"
    exit 0
fi

# Rotate log
[ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt 500 ] && tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

# --- 2/3. Refresh each profile with retry + classification ---------------------
for profile in $PROFILES; do
    prev=$(read_state "$profile")
    ok="False"; out=""; verdict="transient"
    for try in $(seq 1 "$MAX_TRIES"); do
        out=$("$LARK_CLI" contact +get-user --profile "$profile" 2>&1)
        ok=$(echo "$out" | python3 -c "import sys,json; print(json.load(sys.stdin).get('ok',False))" 2>/dev/null || echo "False")
        [ "$ok" = "True" ] && break
        verdict=$(classify_failure "$out")
        # A terminal (auth) failure won't fix itself on retry -> stop retrying immediately.
        [ "$verdict" = "terminal" ] && break
        [ "$try" -lt "$MAX_TRIES" ] && sleep $((try * 3))
    done

    if [ "$ok" = "True" ]; then
        log "OK: $profile token refreshed"
        if [ "$prev" = "terminal" ]; then
            send_feishu "[lark-cli] $profile recovered -- token refreshing normally again"
            log "RECOVERED notice sent for: $profile"
        fi
        write_state "$profile" ok
    elif [ "$verdict" = "terminal" ]; then
        log "TERMINAL: $profile needs re-login: $out"
        if [ "$prev" != "terminal" ]; then
            send_feishu "[lark-cli] token issue: $profile -- needs re-login (auth chain broken)"
            log "ALERT sent for: $profile (OK->terminal transition)"
        else
            log "ALERT suppressed for: $profile (already terminal)"
        fi
        write_state "$profile" terminal
    else
        # Transient failure that survived all retries, though connectivity was up. Do NOT
        # cry re-login -- next cycle will retry. State is 'transient' so a later real recovery
        # from OK is still detectable (terminal->OK), and repeated transients stay quiet.
        log "TRANSIENT: $profile failed after $MAX_TRIES tries (not a re-login case): $out"
        write_state "$profile" transient
    fi
done

# --- 4. Publish freshly-refreshed ACCESS TOKENs to Bitwarden -------------------
# Readers inject these via LARKSUITE_CLI_USER_ACCESS_TOKEN -- no refresh_token ever leaves here.
if [ -x "$HOME/.local/bin/lark-publish-tokens.sh" ]; then
    log "publishing access tokens to Bitwarden..."
    PATH="/usr/bin:/bin:$HOME/.local/bin:$PATH" "$HOME/.local/bin/lark-publish-tokens.sh" >> "$LOG_FILE" 2>&1 || log "WARN: publish failed"
fi
