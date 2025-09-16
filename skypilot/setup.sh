#!/bin/bash
# SkyPilot dotfiles setup script
set -euxo pipefail

# Configuration
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/andylizf/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"
HM_CONFIG="${HM_CONFIG:-gcpuser-linux}"

# Install dependencies
install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y curl git
    fi
}

# Install Nix
install_nix() {
    if ! command -v nix >/dev/null 2>&1; then
        echo "Installing Nix..."
        sh <(curl -L https://nixos.org/nix/install) --no-daemon
    fi

    # Configure Nix
    mkdir -p "$HOME/.config/nix"
    echo "experimental-features = nix-command flakes" > "$HOME/.config/nix/nix.conf"

    # Source Nix profile
    if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
}

# Clone or update dotfiles repository
setup_dotfiles() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        echo "Updating existing dotfiles repository..."
        git -C "$DOTFILES_DIR" fetch origin || true

        if git -C "$DOTFILES_DIR" rev-parse --verify remotes/origin/main >/dev/null 2>&1; then
            git -C "$DOTFILES_DIR" checkout -B main origin/main
            git -C "$DOTFILES_DIR" reset --hard origin/main
        else
            echo "Repository seems corrupted, re-cloning..."
            rm -rf "$DOTFILES_DIR"
            git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        fi
    else
        echo "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

# Apply Home Manager configuration
apply_home_manager() {
    cd "$DOTFILES_DIR"
    echo "Applying Home Manager configuration: $HM_CONFIG"
    nix run home-manager/master -- switch --flake ".#$HM_CONFIG"
}

# Verify installation
verify_installation() {
    echo "=== Verification ==="
    echo "fish: $(fish --version 2>/dev/null || echo 'not installed')"
    echo "node: $(node -v 2>/dev/null || echo 'not installed')"
    echo "gh: $(gh --version 2>&1 | head -n1 || echo 'not installed')"
    echo "git user: $(git config --global user.name 2>/dev/null || echo 'not set') <$(git config --global user.email 2>/dev/null || echo 'not set')>"
    echo "PATH: $PATH"

    # Check if secrets were properly decrypted
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo "SSH key: ✓ ($(stat -c %a "$HOME/.ssh/id_ed25519" 2>/dev/null || stat -f %A "$HOME/.ssh/id_ed25519" 2>/dev/null || echo 'unknown perms'))"
    else
        echo "SSH key: ✗ (not found)"
    fi

    echo "=== Setup Complete ==="
}

# Main execution
main() {
    echo "Starting dotfiles setup..."
    install_deps
    install_nix
    setup_dotfiles
    apply_home_manager
    verify_installation
}

# Run main function
main "$@"