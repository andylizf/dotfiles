#!/usr/bin/env bash
set -euo pipefail

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux)  echo "linux"  ;;
    *)      echo "" ;;
  esac
}

OS_TARGET="$(detect_os)"
if [[ -z "$OS_TARGET" ]]; then
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

# Create a temporary site flake with current user info
SITE_DIR="${TMPDIR:-/tmp}/dotfiles-site-$$"
mkdir -p "$SITE_DIR"
cat > "$SITE_DIR/flake.nix" <<EOF
{
  description = "Site-specific configuration for $USER@$(hostname)";
  outputs = { ... }: {
    homeModule = { ... }: {
      home.username = "$USER";
      home.homeDirectory = "$HOME";
    };
  };
}
EOF

echo "Activating Home Manager configuration for $USER@$HOME"
nix run home-manager/master -- switch \
  --flake "$HERE#$OS_TARGET" \
  --override-input site "path:$SITE_DIR"

# Clean up
rm -rf "$SITE_DIR"
