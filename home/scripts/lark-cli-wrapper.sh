#!/bin/bash
# pull-before-use wrapper for lark-cli (installed over the npm binary; the real one is lark-cli.real).
# Refreshes the local token from Bitwarden (where the always-on writer re-uploads a fresh,
# refresh-stripped token every 30min) so the access token is always fresh. This avoids lark-cli's
# delete-on-failed-refresh behavior. Chain-break is already prevented by the stripped tokens
# (readers have no refresh_token, so they can never break the writer's single-use refresh chain).
# Pull is best-effort (offline-safe) and throttled to once per 15min.
REAL="$HOME/.local/bin/lark-cli.real"
PULL="$HOME/.local/bin/lark-sync-pull.sh"
MARKER="$HOME/.config/lark-sync/.last-pull"

needs_token=1
case "${1:-}" in
  --version|-v|--help|-h|completion|"") needs_token=0 ;;
esac

if [ "$needs_token" = 1 ] && [ -x "$PULL" ]; then
  now=$(date +%s)
  last=0
  [ -f "$MARKER" ] && last=$(cat "$MARKER" 2>/dev/null || echo 0)
  if [ $((now - last)) -gt 900 ]; then
    "$PULL" >/dev/null 2>&1 && echo "$now" > "$MARKER" || true
  fi
fi
exec "$REAL" "$@"
