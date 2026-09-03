#!/usr/bin/env bash
# Claude Code status line. Two rows:
#   claude-fable-5-1[1m] max · 5% ctx
#   5h: 0% (4h53m) · 7d: 53% (0h37m)
#
# Claude Code pipes the session JSON to this script on stdin and renders each
# line it prints. The full input schema is in the built-in statusline-setup
# agent's prompt; the fields read here are model.id, effort.level,
# context_window.used_percentage and rate_limits.{five_hour,seven_day}.
#
# Every status-line row is rendered with ANSI dim applied. Bold cancels dim on
# most terminals, so the bold prefixes below are load-bearing: without them the
# whole row washes out to olive grey. The 256-colour segments (orange 173,
# cyan 44) are not dimmed by the terminal at all, which is why they are written
# as 256-colour rather than as bright basic colours.
#
# It runs on every redraw, so the render path stays at one jq call and no other
# subprocess: jq rounds the percentages, and the helpers assign to globals
# instead of being called through $(...).

set -uo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
CACHE="$CACHE_DIR/usage.tsv"
TIER="$CACHE_DIR/tier.txt"
LOCK="$CACHE_DIR/refresh.lock"
# Beyond this age the cached numbers are dropped rather than drawn. Nothing in
# the render path refreshes them, so an old file means no session has run the
# SessionStart hook or exchanged a message for a while, and a stale percentage
# presented as current is worse than a blank row.
STALE_MAX=1800

# ---------------------------------------------------------------- refresh ---
# `--refresh` is what the SessionStart hook runs, never the render path: it
# makes a network call, and a status line must never block on one. Between that
# hook and the live figures a session writes back below, the cache stays fresh
# without anything being fetched during a redraw.
#
# It asks the same endpoint Claude Code uses for its own limit display:
#   GET https://api.anthropic.com/api/oauth/usage
# which is read-only and consumes no quota, unlike the messages endpoint whose
# response headers are the session's other source for these numbers.
#
# The subscription access token rotates about hourly and Claude Code writes the
# fresh one back to the keychain, so this reads the keychain every time rather
# than caching a token. On 401 it leaves the existing cache alone: refreshing
# the token is a write, and racing Claude Code for it would be worse than
# showing a number a few minutes old.
if [[ ${1:-} == --refresh ]]; then
  mkdir -p "$CACHE_DIR"
  # Atomic single-winner guard. Several sessions redraw at once, and without it
  # each would fire its own request.
  mkdir "$LOCK" 2>/dev/null || exit 0
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT

  # Refresh only where the answer would describe this machine's subscription. A
  # session pointed at another credential has its own, unrelated usage, and
  # writing that account's figures into the shared cache would put a confident
  # wrong number in front of every other session.
  [[ -n ${ANTHROPIC_AUTH_TOKEN:-} || -n ${ANTHROPIC_API_KEY:-} || -n ${ANTHROPIC_BASE_URL:-} ]] && exit 0
  [[ ${CLAUDE_CODE_USE_BEDROCK:-0} == 1 || ${CLAUDE_CODE_USE_VERTEX:-0} == 1 ]] && exit 0

  # An env OAuth token is how the unattended machines authenticate; the Macs
  # log in for real and keep the credential in the keychain.
  tok="${CLAUDE_CODE_OAUTH_TOKEN:-}"
  cred=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null)
  [[ -n $tok ]] || tok=$(printf '%s' "$cred" \
        | python3 -c 'import sys,json;print(json.load(sys.stdin)["claudeAiOauth"]["accessToken"])' 2>/dev/null)

  # The subscription tier is stored beside the token and changes almost never,
  # so it is cached here too rather than shelling out to `security` on a redraw.
  printf '%s' "$cred" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["claudeAiOauth"].get("subscriptionType") or "")' \
      2>/dev/null > "$TIER.tmp" && [[ -s $TIER.tmp ]] && mv "$TIER.tmp" "$TIER"
  rm -f "$TIER.tmp"

  [[ -n $tok ]] || exit 0

  body=$(curl -sS --max-time 10 \
           -H @<(printf 'Authorization: Bearer %s\n' "$tok") \
           -H 'Content-Type: application/json' \
           https://api.anthropic.com/api/oauth/usage 2>/dev/null) || exit 0

  # resets_at comes back as an ISO 8601 string here, while the same field
  # arrives from stdin as epoch seconds. Normalise to epoch so the render path
  # never has to parse a date.
  printf '%s' "$body" | python3 -c '
import sys, json, datetime
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
def one(key):
    v = d.get(key)
    if not isinstance(v, dict) or v.get("utilization") is None:
        return -1, -1
    at = v.get("resets_at")
    if not at:
        return round(v["utilization"]), -1
    try:
        ts = int(datetime.datetime.fromisoformat(at).timestamp())
    except Exception:
        ts = -1
    return round(v["utilization"]), ts
a = one("five_hour"); b = one("seven_day")
if a[0] < 0 and b[0] < 0:
    sys.exit(1)
# Trailing field is when this was fetched. Keeping it in the file means the
# render path can age the cache without shelling out to stat, whose mtime flag
# is spelled differently by the BSD and GNU builds that both turn up in PATH
# on this machine.
now = int(datetime.datetime.now(datetime.timezone.utc).timestamp())
print("\t".join(str(x) for x in (*a, *b, now)))
' > "$CACHE.tmp" 2>/dev/null && [[ -s $CACHE.tmp ]] && mv "$CACHE.tmp" "$CACHE"
  rm -f "$CACHE.tmp"
  exit 0
fi

# ----------------------------------------------------------------- render ---
input=$(cat)

# Every field gets a placeholder ("-" / -1) rather than an empty string: tab is
# an IFS whitespace character, so an empty field would collapse into its
# neighbour and shift every later variable by one.
fields=$(printf '%s' "$input" | jq -r '
  [ .model.id // "?"
  , (.effort.level // "-")
  , (.context_window.used_percentage // -1 | round)
  , (.rate_limits.five_hour.used_percentage // -1 | round)
  , (.rate_limits.five_hour.resets_at // -1)
  , (.rate_limits.seven_day.used_percentage // -1 | round)
  , (.rate_limits.seven_day.resets_at // -1)
  ] | @tsv' 2>/dev/null) || exit 0
[[ -n $fields ]] || exit 0

IFS=$'\t' read -r model effort ctx five_pct five_at seven_pct seven_at <<<"$fields"

ORANGE=$'\033[38;5;173m'
CYAN=$'\033[38;5;44m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
MAGENTA=$'\033[1;35m'
RESET=$'\033[0m'
SEP=$' \033[2m·\033[0m '

now=$(date +%s)

is_int() { [[ $1 =~ ^-?[0-9]+$ ]]; }
has() { is_int "$1" && (($1 >= 0)); }

usage_color() {
  if   (($1 < 50)); then COLOR=$GREEN
  elif (($1 < 80)); then COLOR=$YELLOW
  else                   COLOR=$RED
  fi
}

# Time left until a rate-limit window resets. Days only once past 24h, so the
# 7-day window doesn't render as a three-digit hour count.
fmt_left() {
  local left=$(($1 - now)) h m
  ((left < 0)) && left=0
  h=$((left / 3600)) m=$((left % 3600 / 60))
  if ((h >= 24)); then printf -v LEFT '%dd%dh' $((h / 24)) $((h % 24))
  else                 printf -v LEFT '%dh%dm' "$h" "$m"
  fi
}

# Which credential this session is actually billing against. Claude Code prints
# this in its header ("Claude Max", "API Usage Billing") but does not pass it in
# the status-line JSON, so it is reconstructed from the environment the CLI
# reads. The order mirrors the CLI's own provider resolution: the managed
# providers win, then a gateway base URL, then an explicit key or token, and
# only a session with none of them is on the keychain subscription.
#
# It decides more than a label. rate_limits describes the subscription, so on
# any other credential the cached figures would be a plausible wrong number
# about a different account, and the usage row is left blank instead.
subscription_session=0
if   [[ ${CLAUDE_CODE_USE_BEDROCK:-0} == 1 ]]; then AUTH=bedrock
elif [[ ${CLAUDE_CODE_USE_VERTEX:-0}  == 1 ]]; then AUTH=vertex
elif [[ -n ${ANTHROPIC_BASE_URL:-} ]];         then AUTH=gateway
elif [[ -n ${ANTHROPIC_API_KEY:-} ]];          then AUTH=api
elif [[ -n ${ANTHROPIC_AUTH_TOKEN:-} ]];       then AUTH=oauth
else
  subscription_session=1
  AUTH=sub
  [[ -r $TIER ]] && read -r tier < "$TIER" 2>/dev/null && [[ -n ${tier:-} ]] && AUTH="sub:$tier"
fi

if has "$five_pct" || has "$seven_pct"; then
  # Live values cost nothing and are the freshest available, so they also
  # refresh the cache for whichever session redraws next.
  mkdir -p "$CACHE_DIR" 2>/dev/null
  printf '%s\t%s\t%s\t%s\t%s\n' "$five_pct" "$five_at" "$seven_pct" "$seven_at" "$now" > "$CACHE.tmp" 2>/dev/null \
    && mv "$CACHE.tmp" "$CACHE" 2>/dev/null
elif ((subscription_session)) && [[ -r $CACHE ]]; then
  IFS=$'\t' read -r five_pct five_at seven_pct seven_at fetched_at < "$CACHE" 2>/dev/null
  is_int "${fetched_at:-}" || fetched_at=0
  if (( now - fetched_at > STALE_MAX )); then
    five_pct=-1 seven_pct=-1
  fi
fi

# `claude-fable-5-1[1m]`: the context-window suffix gets its own colour.
base=${model%%\[*}
suffix=${model#"$base"}

line1="${ORANGE}${base}${RESET}"
[[ -n $suffix ]] && line1+="${GREEN}${suffix}${RESET}"
[[ $effort != "-" ]] && line1+=" ${MAGENTA}${effort}${RESET}"
has "$ctx" && line1+="${SEP}${CYAN}${ctx}% ctx${RESET}"
# Green for the subscription, amber for everything else: the distinction worth
# seeing at a glance is whether this session is spending against the plan or
# against something metered.
((subscription_session)) && line1+="${SEP}${GREEN}${AUTH}${RESET}" \
                         || line1+="${SEP}${YELLOW}${AUTH}${RESET}"
printf '%s\n' "$line1"

window() {  # $1=label  $2=percent  $3=resets_at
  has "$2" && has "$3" || return 0
  usage_color "$2"
  fmt_left "$3"
  [[ -n $line2 ]] && line2+="$SEP"
  line2+="${YELLOW}$1:${RESET} ${COLOR}$2% (${LEFT})${RESET}"
}

line2=""
window 5h "$five_pct" "$five_at"
window 7d "$seven_pct" "$seven_at"
[[ -n $line2 ]] && printf '%s\n' "$line2"

exit 0
