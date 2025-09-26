#!/usr/bin/env bash
set -euo pipefail

# Log payloads so we can confirm the CLI actually invokes the script.
log_file="$HOME/.codex/notify_bell.log"
printf '%(%Y-%m-%d %H:%M:%S)T %s\n' -1 "${1:-<no-payload>}" >> "$log_file" 2>/dev/null || true

ring_bell() {
  local dest="$1"
  if [[ -n "$dest" && -w "$dest" ]]; then
    printf '\a' >"$dest"
    return 0
  fi
  return 1
}

# If stdout is already a TTY just write the bell there.
if [[ -t 1 ]]; then
  printf '\a'
  exit 0
fi

# Fall back to the current shell's controlling TTY.
current_tty=$(ps -o tty= -p $$ | tr -d ' ')
if ring_bell "/dev/$current_tty"; then
  exit 0
fi

# Last resort: try the parent's TTY (Codex CLI when it has one).
parent_pid=$(ps -o ppid= -p $$)
parent_tty=$(ps -o tty= -p "$parent_pid" | tr -d ' ')
if ring_bell "/dev/$parent_tty"; then
  exit 0
fi

exit 0
