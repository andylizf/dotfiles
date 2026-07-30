#!/usr/bin/env bash
set -euo pipefail

token_file="${NOTION_TOKEN_FILE:-$HOME/.config/notion/token}"

if [[ ! -r "$token_file" ]]; then
  printf 'notion-mcp-wrapper: token file is missing or unreadable: %s\n' "$token_file" >&2
  exit 78
fi

notion_token="$(tr -d '\r\n' < "$token_file")"
if [[ -z "$notion_token" ]]; then
  printf 'notion-mcp-wrapper: token file is empty: %s\n' "$token_file" >&2
  exit 78
fi

# Claude may launch MCP servers outside an interactive shell. Include the
# Home Manager and user-level Node locations explicitly so npx is deterministic.
export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin${PATH:+:$PATH}"
export NOTION_TOKEN="$notion_token"
unset notion_token

exec npx -y @notionhq/notion-mcp-server "$@"
