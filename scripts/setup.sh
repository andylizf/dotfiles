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
if [ -z "${USER:-}" ]; then
  export USER="$RUN_USER"
fi

log() { printf "[setup] %s\n" "$*"; }

ensure_nix_features() {
  local nix_conf="$HOME/.config/nix/nix.conf"
  mkdir -p "$(dirname "$nix_conf")"
  if ! grep -q 'nix-command' "$nix_conf" 2>/dev/null; then
    log "Enabling nix-command/flakes in $nix_conf…"
    printf 'experimental-features = nix-command flakes\n' >>"$nix_conf"
  fi
}

ensure_shell_inits() {
  local rc
  local snippet='if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then\n  . "$HOME/.nix-profile/etc/profile.d/nix.sh"\nfi'

  for rc in "$HOME/.profile" "$HOME/.bashrc"; do
    if [ ! -f "$rc" ] || ! grep -Fq '.nix-profile/etc/profile.d/nix.sh' "$rc"; then
      printf '\n%s\n' "$snippet" >>"$rc"
      log "Added nix profile sourcing to $rc"
    fi
  done
}

install_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Installing apt deps (curl git)…"
    sudo apt-get update -y
    sudo apt-get install -y curl git
  fi
}

install_nix() {
  local profile_sh="$HOME/.nix-profile/etc/profile.d/nix.sh"
  if [ -f "$profile_sh" ]; then
    # shellcheck disable=SC1090
    . "$profile_sh" || true
  fi
  if [ -d "$HOME/.nix-profile/bin" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi

  # If a previous multi-user install exists (root-owned /nix), remove it so we can
  # reinstall as a single user. This keeps SkyPilot jobs from tripping over daemon locks.
  if [ -d /nix/var/nix/db ] && [ ! -w /nix/var/nix/db ]; then
    log "Removing existing multi-user Nix installation…"
    sudo sh -c 'systemctl stop nix-daemon 2>/dev/null' || true
    sudo rm -rf /nix /etc/nix /etc/profile.d/nix-daemon.sh /etc/profile.d/nix.sh
  fi

  if ! command -v nix >/dev/null 2>&1; then
    log "Installing single-user Nix…"
    sh <(curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install) --no-daemon --yes
  fi

  if [ -f "$profile_sh" ]; then
    # shellcheck disable=SC1090
    . "$profile_sh"
  fi
  if [ -d "$HOME/.nix-profile/bin" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi

  ensure_nix_features
  ensure_shell_inits
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
