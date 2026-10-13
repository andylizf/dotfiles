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
#  4. Alert de-dup via per-profile state: the Feishu "needs re-login" alert fires on an
#     OK->terminal transition and then once a week for as long as the profile stays dead,
#     plus a "recovered" notice on terminal->OK. No 10-min spam, and no permanent silence
#     either -- a dead profile nobody mentions again reads exactly like a working one.
#  5. A never-truncated transitions log beside the main one, so a death weeks old can still
#     be dated after the main log has rolled over it.
#  6. The pre-check in 1 no longer skips in silence forever: an unbroken skip streak past
#     12 hours is announced, because nothing refreshes during one and the refresh window
#     it is eating is only 7 days long.
#  7. A lock, so a hand-run of this script cannot refresh a profile alongside the timer's
#     own cycle and spend a token the other one already replaced.
#
# What a cycle actually does, because the log used to overstate it: it probes each profile's
# USER identity. lark-cli refreshes only once the access token has expired, and that token
# lasts 2h while this job runs every 10 min, so most cycles refresh nothing and the log says
# only that the identity was accepted. To see whether a refresh really happened, read
# `lark-cli auth status --profile <name>`: `expiresAt` moves to last-refresh + 2h and
# `refreshExpiresAt` to last-refresh + 7 days, so both standing still means it did not.
set -uo pipefail

LARK_CLI="$HOME/.local/bin/lark-cli.real"
[ -x "$LARK_CLI" ] || LARK_CLI="$HOME/.local/bin/lark-cli"
CFG_DIR="$HOME/.config/lark-sync"
LOG_FILE="$CFG_DIR/lark-refresh.log"
TRANSITIONS_LOG="$CFG_DIR/lark-transitions.log"
STATE_DIR="$CFG_DIR/state"
SKIP_SINCE="$CFG_DIR/state/skip-since"   # epoch of the first cycle in the current skip streak
LOCK_DIR="$CFG_DIR/state/refresh.lock"   # one refresh at a time; see acquire_lock
REALERT_SECONDS=604800   # a profile that stays dead says so again once a week
SKIP_ALERT_AFTER=43200   # 12h of unbroken skipped cycles is an outage, not node jitter
SKIP_REALERT=86400       # and then once a day for as long as it lasts
PROXY="http://127.0.0.1:7897"
WEBHOOK_FILE="$CFG_DIR/feishu-webhook"
PROFILES="personal cheese"
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

# Say WHY a terminal verdict is terminal, in the log, in plain words.
#
# Without this the log only carries lark-cli's raw error, and the most common one reads
#   "bot identity cannot get current user info, specify --user-id"
# which looks exactly like a caller bug — as if the probe passed the wrong identity and
# just needs a --user-id or --as user. It doesn't. The probe passes NO identity on purpose:
# lark-cli falling back to bot is precisely the evidence that the user credential is gone.
# That misreading cost a debugging session on 2026-07-31, so the explanation now ships with
# the verdict instead of living only in the comment above classify_failure().
explain_terminal() {
    case "$1" in
        *"bot identity"*|*'"identity": "bot"'*|*'"identity":"bot"'*)
            echo "lark-cli fell back to BOT identity, which means the USER credential for this profile is gone. This is NOT a wrong-flag bug: the probe passes no identity on purpose, so a fallback to bot IS the failure signal. Adding --as user or --user-id will not fix it." ;;
        *"invalid access token"*|*token_invalid*|*"token.*expired"*)
            echo "Feishu rejected the access token and it could not be refreshed from the stored refresh_token." ;;
        *invalid_grant*|*refresh*token*)
            echo "the refresh_token is expired or was invalidated, so the single-use refresh chain is broken." ;;
        *)
            echo "authentication failed in a way that retrying will not fix." ;;
    esac
}

read_state()  { cat "$STATE_DIR/$1.state" 2>/dev/null || echo unknown; }

# The number in a marker file, or the fallback when the file is missing, empty or junk:
# an unreadable marker must not turn the arithmetic that uses it into a syntax error.
read_number() {
    local v; v=$(cat "$1" 2>/dev/null)
    case "$v" in ""|*[!0-9]*) echo "$2" ;; *) echo "$v" ;; esac
}

# $LOG_FILE is truncated to its last 250 lines, and one dead profile writes ~20 lines of raw
# rejection every cycle, so it holds roughly 90 minutes — it cannot say when a profile died
# weeks ago. $TRANSITIONS_LOG takes one line per actual state change and is never truncated:
# it stays small because a healthy profile produces no lines at all.
write_state() {
    local prev; prev=$(read_state "$1")
    echo "$2" > "$STATE_DIR/$1.state"
    [ "$prev" = "$2" ] && return 0
    echo "[$(date '+%Y-%m-%d %H:%M:%S%z')] $1: $prev -> $2" >> "$TRANSITIONS_LOG"
}

# Seconds since this profile's last re-login alert; a number past any threshold if never.
since_last_alert() {
    local stamp="$STATE_DIR/$1.alerted"
    [ -f "$stamp" ] || { echo 999999999; return; }
    echo $(( $(date +%s) - $(read_number "$stamp" 0) ))
}
mark_alerted()  { date +%s > "$STATE_DIR/$1.alerted"; }
clear_alerted() { rm -f "$STATE_DIR/$1.alerted"; }

# One refresh at a time. A Feishu refresh token is single-use, so two runs refreshing the same
# profile means the second spends a token the first already replaced, and the chain dies -- the
# exact failure this script exists to prevent. launchd will not overlap its own scheduled cycles
# (measured), so what this guards is a hand-run of the script racing the timer.
acquire_lock() {
    mkdir "$LOCK_DIR" 2>/dev/null && { echo $$ > "$LOCK_DIR/pid"; return 0; }
    local holder; holder=$(read_number "$LOCK_DIR/pid" 0)
    if [ "$holder" != 0 ] && kill -0 "$holder" 2>/dev/null; then
        return 1
    fi
    # The holder is gone: a killed run leaves the directory behind. Clear it and take the lock
    # the normal way, so two runs racing to take over cannot both believe they won.
    rm -rf "$LOCK_DIR"
    mkdir "$LOCK_DIR" 2>/dev/null || return 1
    echo $$ > "$LOCK_DIR/pid"
    log "took over a lock left behind by pid $holder"
    return 0
}
release_lock() { rm -rf "$LOCK_DIR"; }

if ! acquire_lock; then
    log "SKIP cycle: another refresh run is in progress (pid $(cat "$LOCK_DIR/pid" 2>/dev/null)); a second one would spend the same single-use token"
    exit 0
fi
trap release_lock EXIT

# Rotate log. Ahead of the pre-check, because a skipped cycle logs a line too and an
# outage lasting days would otherwise grow this file until connectivity came back.
[ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt 500 ] && tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

# --- 1. Connectivity pre-check -------------------------------------------------
# Skipping is the safe response to an outage and stays silent while it looks like jitter.
# What is not safe is skipping indefinitely in silence: a refresh window is 7 days and only
# rolls forward when a refresh succeeds, so an outage that outlasts it expires every
# credential at once, and the first anyone hears of it is a profile asking for a re-login.
if ! feishu_reachable; then
    log "SKIP cycle: Feishu unreachable (connectivity pre-check failed); credentials untouched"
    write_state connectivity unreachable
    now=$(date +%s)
    [ -f "$SKIP_SINCE" ] || echo "$now" > "$SKIP_SINCE"
    streak=$(( now - $(read_number "$SKIP_SINCE" "$now") ))
    if [ "$streak" -ge "$SKIP_ALERT_AFTER" ] && [ "$(since_last_alert connectivity)" -ge "$SKIP_REALERT" ]; then
        send_feishu "[lark-cli] Feishu has been unreachable from the writer for $((streak / 3600))h, so nothing has refreshed in that time. Credentials are untouched and safe for now, but a refresh window is 7 days: past that every profile needs a manual re-login. Check this machine's network."
        mark_alerted connectivity
        log "ALERT sent: Feishu unreachable for $((streak / 3600))h"
    fi
    exit 0
fi

if [ -f "$SKIP_SINCE" ]; then
    now=$(date +%s); streak=$(( now - $(read_number "$SKIP_SINCE" "$now") ))
    log "connectivity back after $((streak / 60))m of skipped cycles"
    [ -f "$STATE_DIR/connectivity.alerted" ] &&
        send_feishu "[lark-cli] Feishu is reachable from the writer again after $((streak / 3600))h; refreshing has resumed."
    clear_alerted connectivity
    rm -f "$SKIP_SINCE"
fi
write_state connectivity reachable

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
        log "OK: $profile healthy (user identity accepted)"
        if [ "$prev" = "terminal" ]; then
            send_feishu "[lark-cli] $profile recovered -- token refreshing normally again"
            log "RECOVERED notice sent for: $profile"
        fi
        clear_alerted "$profile"
        write_state "$profile" ok
    elif [ "$verdict" = "terminal" ]; then
        # Three lines, in this order: what it means, how to fix it, then the raw output.
        # Whoever reads this next (human or agent) should not have to open this script to
        # find out that "bot identity" means "the credential is gone".
        log "TERMINAL: $profile needs re-login -- $(explain_terminal "$out")"
        log "TERMINAL: $profile fix -- on THIS host (the writer) run: lark-cli auth login --profile $profile --no-wait --json, send the verification URL to the account owner, then complete it with --device-code   (readers cannot re-auth; doing so would fork the single-use refresh chain)"
        log "TERMINAL: $profile raw -- $out"
        # De-dup, but never into permanent silence: alerting only on the OK->terminal
        # transition once left a dead profile unmentioned for twelve days, which reads
        # exactly like a working one.
        alert_age=$(since_last_alert "$profile")
        if [ "$prev" != "terminal" ]; then
            send_feishu "[lark-cli] token issue: $profile -- needs re-login (auth chain broken). $(explain_terminal "$out") Fix on the writer host: lark-cli auth login --profile $profile"
            mark_alerted "$profile"
            log "ALERT sent for: $profile (OK->terminal transition)"
        elif [ "$alert_age" -ge "$REALERT_SECONDS" ]; then
            send_feishu "[lark-cli] $profile is STILL dead $((alert_age / 86400)) days after the last notice -- nothing has refreshed since. Fix on the writer host: lark-cli auth login --profile $profile --no-wait --json, then finish it with --device-code"
            mark_alerted "$profile"
            log "ALERT re-sent for: $profile (still terminal, $((alert_age / 86400))d since last notice)"
        else
            log "ALERT suppressed for: $profile (already terminal, last notice $((alert_age / 3600))h ago)"
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
