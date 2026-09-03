#!/usr/bin/env bash
# Claude Code status line. Two rows:
#   claude-fable-5-1[1m] max · 5% ctx · sub:max
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
# The render path makes one jq call and starts no other subprocess: jq rounds
# the percentages, the credential is resolved from environment variables alone,
# and the helpers assign to globals instead of being called through $(...).

set -uo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
# Beyond this age the cached numbers are dropped rather than drawn. Nothing in
# the render path refreshes them, so an old file means no session on this
# credential has run the SessionStart hook or exchanged a message for a while,
# and a stale percentage presented as current is worse than a blank row.
STALE_MAX=1800

# ------------------------------------------------------------- credential ---
# Which credential this session bills against. Claude Code prints this in its
# header ("Claude Max", "API Usage Billing") but does not pass it in the
# status-line JSON, so it is reconstructed from the environment the CLI reads,
# in the CLI's own resolution order: the managed providers win, then a gateway
# base URL, then an explicit key or token, and a session with none of them is
# on the keychain login.
#
# AUTH is the label. USAGE_SLOT names the cache file, and is empty for a
# credential that has no subscription usage to show at all. Usage is per
# account, so each credential gets its own file: one shared file would let a
# session display another account's figures, which look entirely plausible and
# are simply wrong.
#
# 32-bit FNV-1a in pure bash. A hash rather than a slice of the token because
# the slot name lands in a filename, and a filename should not carry any part
# of a credential. ~110 iterations of integer arithmetic, no subprocess.
fingerprint() {
  local s=$1 i c h=2166136261
  for ((i = 0; i < ${#s}; i++)); do
    printf -v c '%d' "'${s:i:1}"
    h=$(( ((h ^ c) * 16777619) & 0xFFFFFFFF ))
  done
  printf -v FP '%08x' "$h"
}

# Only an OAuth access token carrying user:profile can answer the usage
# endpoint, and holding one is rarer than it looks: `claude setup-token` mints
# user:inference alone, so a token from it authenticates and infers perfectly
# while returning 403 here. The wide set comes from a real login, whose
# credential the CLI keeps in the keychain rather than in any variable.
#
# ANTHROPIC_AUTH_TOKEN is a free-form bearer that may be pointed at anything,
# so it qualifies only when it looks like an OAuth token, and even then the 403
# is expected rather than exceptional. It writes no cache, so the row simply
# stays blank.
resolve_credential() {
  AUTH="" USAGE_SLOT="" SUBSCRIPTION=0 STORE_DIR=""
  if   [[ ${CLAUDE_CODE_USE_BEDROCK:-0} == 1 ]]; then AUTH=bedrock; return
  elif [[ ${CLAUDE_CODE_USE_VERTEX:-0}  == 1 ]]; then AUTH=vertex;  return
  elif [[ -n ${ANTHROPIC_BASE_URL:-} ]];         then AUTH=gateway; return
  elif [[ -n ${ANTHROPIC_API_KEY:-} ]];          then AUTH=api;     return
  elif [[ -n ${ANTHROPIC_AUTH_TOKEN:-} ]]; then
    AUTH=oauth
    [[ $ANTHROPIC_AUTH_TOKEN == sk-ant-oat* ]] || return
    fingerprint "$ANTHROPIC_AUTH_TOKEN"; USAGE_SLOT=$FP; return
  elif [[ -n ${CLAUDE_CODE_OAUTH_TOKEN:-} ]]; then
    # How the unattended machines authenticate. Still the subscription, so it
    # is labelled as one; the tier is unknown without the keychain entry.
    #
    # Usually there is no usage to fetch. The CLI treats this variable's scopes
    # as CLAUDE_CODE_OAUTH_SCOPES, defaulting to user:inference alone, which is
    # exactly what `claude setup-token` mints and is one scope short of what the
    # usage endpoint requires. Reading the same variable keeps the request from
    # being made when it can only 403, and turns it on by itself if the token is
    # ever reissued with the wider set.
    AUTH=sub; SUBSCRIPTION=1
    [[ ${CLAUDE_CODE_OAUTH_SCOPES:-user:inference} == *user:profile* ]] || return
    fingerprint "$CLAUDE_CODE_OAUTH_TOKEN"; USAGE_SLOT=$FP; return
  fi
  # A real login, whose credential sits in a keychain entry named after the
  # store directory. Two accounts are kept side by side by pointing one session
  # at a different directory, so the cache follows the same rule or there would
  # be one file for two accounts.
  #
  # The CLI picks that directory as CLAUDE_SECURESTORAGE_CONFIG_DIR when set,
  # else CLAUDE_CONFIG_DIR, and treats the entry as the unsuffixed default when
  # neither is. Set-but-empty means the default too, which is why this tests for
  # the variable being defined rather than for a value. Prefer the first: it
  # moves the credential alone, while CLAUDE_CONFIG_DIR moves the whole config
  # home, transcripts, settings and plugins included.
  AUTH=sub; SUBSCRIPTION=1; USAGE_SLOT=keychain
  if [[ -n ${CLAUDE_SECURESTORAGE_CONFIG_DIR+set} ]]; then
    STORE_DIR=$CLAUDE_SECURESTORAGE_CONFIG_DIR
  elif [[ -n ${CLAUDE_CONFIG_DIR:-} ]]; then
    STORE_DIR=$CLAUDE_CONFIG_DIR
  fi
  if [[ -n $STORE_DIR ]]; then
    fingerprint "$STORE_DIR"; USAGE_SLOT="cfg-$FP"
  fi
}

resolve_credential
CACHE="$CACHE_DIR/usage-$USAGE_SLOT.tsv"
TIER="$CACHE_DIR/tier-$USAGE_SLOT.txt"
LOCK="$CACHE_DIR/refresh-$USAGE_SLOT.lock"

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
# A keychain access token rotates about hourly and Claude Code writes the fresh
# one back, so it is read at call time rather than cached. On 401 the existing
# cache is left alone: refreshing the token is a write, and racing Claude Code
# for it would be worse than showing a number a few minutes old.
if [[ ${1:-} == --refresh ]]; then
  [[ -n $USAGE_SLOT ]] || exit 0
  mkdir -p "$CACHE_DIR" && chmod 700 "$CACHE_DIR" 2>/dev/null
  rm -f "$CACHE_DIR/usage.tsv"   # single-slot layout from an earlier revision
  # Atomic single-winner guard. Several sessions start at once, and without it
  # each would fire its own request.
  mkdir "$LOCK" 2>/dev/null || exit 0
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT

  tok="${ANTHROPIC_AUTH_TOKEN:-${CLAUDE_CODE_OAUTH_TOKEN:-}}"
  if [[ -z $tok ]]; then
    # Same service name the CLI derives: the default entry, suffixed with the
    # first 8 hex of sha256 over the store directory resolved above. That suffix
    # is what keeps a second account's credential from overwriting the first, so
    # reading the wrong entry here would report the wrong account's usage.
    svc='Claude Code-credentials'
    [[ -n $STORE_DIR ]] && svc+="-$(printf '%s' "$STORE_DIR" | shasum -a 256 | cut -c1-8)"
    cred=$(security find-generic-password -s "$svc" -w 2>/dev/null)
    tok=$(printf '%s' "$cred" \
          | python3 -c 'import sys,json;print(json.load(sys.stdin)["claudeAiOauth"]["accessToken"])' 2>/dev/null)
    # The tier sits beside the token and changes almost never, so it is cached
    # here too rather than shelling out to `security` on a redraw.
    printf '%s' "$cred" \
      | python3 -c 'import sys,json;print(json.load(sys.stdin)["claudeAiOauth"].get("subscriptionType") or "")' \
        2>/dev/null > "$TIER.tmp" && [[ -s $TIER.tmp ]] && mv "$TIER.tmp" "$TIER"
    rm -f "$TIER.tmp"
  fi
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

# stdin carries rate_limits only after this session's first API response. The
# cache covers the gap before it lands, and is written back from the live
# figures so the next session on this credential starts with fresh numbers.
if has "$five_pct" || has "$seven_pct"; then
  if [[ -n $USAGE_SLOT ]]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null && chmod 700 "$CACHE_DIR" 2>/dev/null
    printf '%s\t%s\t%s\t%s\t%s\n' "$five_pct" "$five_at" "$seven_pct" "$seven_at" "$now" > "$CACHE.tmp" 2>/dev/null \
      && mv "$CACHE.tmp" "$CACHE" 2>/dev/null
  fi
elif [[ -n $USAGE_SLOT && -r $CACHE ]]; then
  IFS=$'\t' read -r five_pct five_at seven_pct seven_at fetched_at < "$CACHE" 2>/dev/null
  is_int "${fetched_at:-}" || fetched_at=0
  (( now - fetched_at > STALE_MAX )) && five_pct=-1 seven_pct=-1
fi

# The tier is only known for a keychain login, where it was read alongside the
# token; an env token authenticates fine without revealing which plan.
if ((SUBSCRIPTION)) && [[ -r $TIER ]]; then
  read -r tier < "$TIER" 2>/dev/null
  [[ -n ${tier:-} ]] && AUTH="sub:$tier"
fi

# `claude-fable-5-1[1m]`: the context-window suffix gets its own colour.
base=${model%%\[*}
suffix=${model#"$base"}

line1="${ORANGE}${base}${RESET}"
[[ -n $suffix ]] && line1+="${GREEN}${suffix}${RESET}"
[[ $effort != "-" ]] && line1+=" ${MAGENTA}${effort}${RESET}"
has "$ctx" && line1+="${SEP}${CYAN}${ctx}% ctx${RESET}"
# Green for the subscription, amber for everything else: the distinction worth
# seeing at a glance is whether this session spends against the plan or against
# something metered.
((SUBSCRIPTION)) && line1+="${SEP}${GREEN}${AUTH}${RESET}" \
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
