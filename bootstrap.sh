#!/usr/bin/env bash
set -euo pipefail

detect_target() {
  case "$(uname -s)" in
    Darwin) echo "user-darwin" ;;
    Linux)  echo "user-linux"  ;;
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
  echo "Installing Nix with Zero to Nix installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Activating Home Manager configuration for user: $USER at $HOME"
nix run home-manager/master -- switch --flake "$HERE#$TARGET" --override-input nixpkgs/lib.home.username "$USER" --override-input nixpkgs/lib.home.homeDirectory "$HOME"
