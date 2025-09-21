#!/usr/bin/env bash
set -euo pipefail

# Unified installer/runner for local and SkyPilot environments.
# - Installs minimal deps (curl/git) on apt-based systems
# - Installs Nix (Zero to Nix) if missing and enables flakes
# - Clones or updates the dotfiles repo if needed
# - Auto-injects USER/HOME via a temporary site flake and activates Home Manager

: "${DOTFILES_REPO:=https://github.com/andylizf/dotfiles.git}"
: "${DOTFILES_DIR:=$HOME/dotfiles}"

# Some environments (e.g., SkyPilot setup) run as root with USER unset; fall back to `id -un`.
RUN_USER="${USER:-$(id -un)}"
if [ "$RUN_USER" = "root" ] && [ "${HOME:-/root}" != "/root" ]; then
  RUN_USER="$(basename "${HOME:-/root}")"
fi

log() { printf "[setup] %s\n" "$*"; }

install_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Installing apt deps (curl git)…"
    sudo apt-get update -y
    sudo apt-get install -y curl git
  fi
}

install_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    log "Installing Nix with Zero to Nix installer…"
    curl --proto '=https' --tlsv1.2 -sSf -L \
      https://install.determinate.systems/nix | sh -s -- install --no-confirm
  fi

  # Source daemon profile if present (multi-user) else single-user profile.
  # Zero to Nix generally wires this up, but sourcing helps in non-login shells (e.g., CI/SkyPilot).
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
  elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

ensure_repo() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "Updating existing repo at $DOTFILES_DIR…"
    git -C "$DOTFILES_DIR" fetch --all -q
    git -C "$DOTFILES_DIR" checkout -B main origin/main -q
    git -C "$DOTFILES_DIR" reset --hard origin/main -q
  else
    log "Cloning repo to $DOTFILES_DIR…"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

main() {
  log "Starting unified setup…"
  install_deps
  install_nix
  ensure_repo

  cd "$DOTFILES_DIR"
  # Detect OS target
  case "$(uname -s)" in
    Darwin) OS_TARGET="darwin" ;;
    Linux)  OS_TARGET="linux"  ;;
    *)      log "Unsupported OS: $(uname -a)"; exit 1 ;;
  esac

  # Create a temporary site flake with current user info (pure flakes, no --impure)
  SITE_DIR="${TMPDIR:-/tmp}/dotfiles-site-$$"
  mkdir -p "$SITE_DIR"
  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    ENABLE_SECRETS_LINE='dotfiles.enableSecrets = true;'
  else
    ENABLE_SECRETS_LINE=''
  fi
  cat > "$SITE_DIR/flake.nix" <<EOF
{
  description = "Site-specific configuration for $RUN_USER@$(hostname)";
  outputs = { ... }: {
    homeModule = { ... }: {
      home.username = "$RUN_USER";
      home.homeDirectory = "$HOME";
      $ENABLE_SECRETS_LINE
    };
  };
}
EOF

  log "Activating Home Manager (#$OS_TARGET) with site override…"
  nix run home-manager/master -- switch \
    --flake ".#$OS_TARGET" \
    --override-input site "path:$SITE_DIR"

  rm -rf "$SITE_DIR"
}

main "$@"
