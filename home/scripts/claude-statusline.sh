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
# It runs on every redraw, so it stays at one jq call and no other subprocess:
# jq rounds the percentages, and the helpers assign to globals instead of being
# called through $(...).

set -uo pipefail

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

# `claude-fable-5-1[1m]`: the context-window suffix gets its own colour.
base=${model%%\[*}
suffix=${model#"$base"}

line1="${ORANGE}${base}${RESET}"
[[ -n $suffix ]] && line1+="${GREEN}${suffix}${RESET}"
[[ $effort != "-" ]] && line1+=" ${MAGENTA}${effort}${RESET}"
if is_int "$ctx" && ((ctx >= 0)); then
  line1+="${SEP}${CYAN}${ctx}% ctx${RESET}"
fi
printf '%s\n' "$line1"

# rate_limits is absent before the first API response, and for non-subscribers.
window() {  # $1=label  $2=percent  $3=resets_at
  is_int "$2" && (($2 >= 0)) || return 0
  is_int "$3" && (($3 >= 0)) || return 0
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
