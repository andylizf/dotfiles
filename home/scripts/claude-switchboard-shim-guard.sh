#!/bin/bash
# Keep Claude Code behind the account switchboard when the native updater
# replaces ~/.local/bin/claude with a new version symlink.
set -euo pipefail

BIN="$HOME/.local/bin"
STATE="$HOME/.claude-switchboard"
LOG="$STATE/shim-guard.log"

mkdir -p "$STATE"
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S%z')" "$*" >> "$LOG"; }

write_shim() {
  cat > "$BIN/claude.switchboard.tmp" <<'SHIM'
#!/bin/bash
# The switchboard executes claude-real directly, so this wrapper cannot recurse.
exec "$HOME/.local/bin/claude-switchboard" run -- "$@"
SHIM
  chmod 755 "$BIN/claude.switchboard.tmp"
  mv -f "$BIN/claude.switchboard.tmp" "$BIN/claude"
}

restore_native() {
  if [ -f "$BIN/claude" ] \
     && grep -q 'claude-switchboard.*run --' "$BIN/claude" 2>/dev/null \
     && [ -e "$BIN/claude-real" ]; then
    mv -f "$BIN/claude-real" "$BIN/claude"
    log "restored native Claude because claude-switchboard is unavailable"
  fi
}

if [ ! -x "$BIN/claude-switchboard" ]; then
  restore_native
  exit 0
fi

if [ ! -e "$BIN/claude" ]; then
  log "claude is missing; left it alone"
  exit 0
fi

if [ -L "$BIN/claude" ]; then
  target="$(readlink "$BIN/claude")"
  if [ -x "$target" ]; then
    ln -sfn "$target" "$BIN/claude-real"
    write_shim
    log "installed shim for $target"
  else
    log "claude points to a missing target: $target"
  fi
  exit 0
fi

if grep -q 'claude-switchboard.*run --' "$BIN/claude" 2>/dev/null; then
  if [ ! -e "$BIN/claude-real" ]; then
    log "shim exists but claude-real is missing"
    exit 1
  fi
  exit 0
fi

if [ ! -e "$BIN/claude-real" ]; then
  mv -f "$BIN/claude" "$BIN/claude-real"
  write_shim
  log "preserved a native Claude file as claude-real"
else
  log "claude is a non-shim file and claude-real already exists; left it alone"
  exit 1
fi
