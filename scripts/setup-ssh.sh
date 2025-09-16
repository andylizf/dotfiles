#!/usr/bin/env bash
set -euo pipefail

EMAIL=${1:-"andylizf@outlook.com"}

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "Generating SSH key (ed25519) for $EMAIL ..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
else
  echo "SSH key already exists at ~/.ssh/id_ed25519; skipping generation."
fi

if command -v gh >/dev/null 2>&1; then
  echo "Uploading public key to GitHub via gh ..."
  gh ssh-key add "$HOME/.ssh/id_ed25519.pub" -t "$(hostname)-$(date +%Y%m%d)" || true
else
  echo "gh CLI not found. Manually upload ~/.ssh/id_ed25519.pub in GitHub settings."
fi

