#!/usr/bin/env bash
set -euo pipefail

detect_target() {
  case "$(uname -s)" in
    Darwin) echo "andyl-darwin" ;;
    Linux)  echo "andyl-linux"  ;;
    *)      echo "" ;;
  esac
}

TARGET="$(detect_target)"
if [[ -z "$TARGET" ]]; then
  echo "Unsupported OS: $(uname -a)" >&2
  exit 1
fi

# Install Nix if missing
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
  # shellcheck disable=SC1091
  . "$HOME/.nix-profile/etc/profile.d/nix.sh" || true
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Activating Home Manager configuration: #$TARGET"
nix run home-manager/master -- switch --flake "$HERE#$TARGET"

echo
echo "Done. If fish is not your login shell yet, run:"
echo "  chsh -s \"$(command -v fish)\""

