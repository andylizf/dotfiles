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

HOST_NAME="$(
  if command -v hostname >/dev/null 2>&1; then
    hostname
  elif [ -r /proc/sys/kernel/hostname ]; then
    cat /proc/sys/kernel/hostname
  else
    uname -n 2>/dev/null || echo "unknown-host"
  fi
)"
HOST_NAME="${HOST_NAME:-unknown-host}"

log() { printf "[setup] %s\n" "$*"; }

multiuser_source_env() {
  # Source multi-user Nix profile for both Linux and macOS if present
  local pf="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  if [ -f "$pf" ]; then
    # shellcheck disable=SC1090
    . "$pf" || true
    export NIX_REMOTE=${NIX_REMOTE:-daemon}
  fi
  if [ -d "/nix/var/nix/profiles/default/bin" ]; then
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  fi
}

darwin_start_daemons() {
  if [ "$(uname -s)" != "Darwin" ]; then return; fi
  for svc in org.nixos.darwin-store org.nixos.nix-daemon; do
    if [ -f "/Library/LaunchDaemons/$svc.plist" ]; then
      sudo launchctl bootstrap system "/Library/LaunchDaemons/$svc.plist" >/dev/null 2>&1 || true
      sudo launchctl enable system/$svc >/dev/null 2>&1 || true
      sudo launchctl kickstart -k system/$svc >/dev/null 2>&1 || true
    fi
  done
}

darwin_wait_daemon() {
  if [ "$(uname -s)" != "Darwin" ]; then return 0; fi
  local sock="/nix/var/nix/daemon-socket/socket"
  for _ in $(seq 1 60); do
    if [ -S "$sock" ]; then return 0; fi
    sleep 0.5
  done
  return 1
}

darwin_repair_if_needed() {
  if [ "$(uname -s)" != "Darwin" ]; then return; fi
  if [ -x /nix/nix-installer ]; then
    sudo /nix/nix-installer repair || true
  fi
}

ensure_nix_features() {
  local nix_conf="$HOME/.config/nix/nix.conf"
  mkdir -p "$(dirname "$nix_conf")"
  if ! grep -q 'nix-command' "$nix_conf" 2>/dev/null; then
    log "Enabling nix-command/flakes in $nix_conf..."
    printf 'experimental-features = nix-command flakes\n' >>"$nix_conf"
  fi
}

ensure_shell_inits() {
  local rc
  local snippet='if [ -z "${USER-}" ]; then
  export USER="$(id -un)"
fi
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi'

  for rc in "$HOME/.profile" "$HOME/.bashrc"; do
    if [ ! -f "$rc" ] || ! grep -Fq '.nix-profile/etc/profile.d/nix.sh' "$rc"; then
      printf '\n%s\n' "$snippet" >>"$rc"
      log "Added nix profile sourcing to $rc"
    fi
  done
}

register_login_shell() {
  local fish_path="$HOME/.nix-profile/bin/fish"
  if [ -x "$fish_path" ] && ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
    log "Registering $fish_path in /etc/shells..."
    sudo sh -c "printf '%s\\n' '$fish_path' >> /etc/shells"
  fi
}

install_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Installing apt deps (curl git)..."
    sudo apt-get update -y
    sudo apt-get install -y curl git
  fi
}

ensure_bwrap_if_needed() {
  # For Linux single-user installs, bubblewrap is required so that /nix/store
  # exists inside the build chroot. Install it if missing on apt systems.
  if [ "$(uname -s)" = "Linux" ] && ! command -v bwrap >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      log "Installing bubblewrap for single-user Nix..."
      sudo apt-get install -y bubblewrap || true
    fi
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

  local sys="$(uname -s)"
  local install_multi_user="false"
  if [ "$sys" = "Darwin" ]; then
    install_multi_user="true"
  else
    # On Linux, prefer multi-user when systemd + sudo are available
    if [ "$(id -u)" -eq 0 ]; then
      install_multi_user="true"
    elif command -v sudo >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
      install_multi_user="true"
    fi
  fi

  # If we are about to install single-user on Linux but a multi-user install exists,
  # remove it to avoid daemon locks on ephemeral hosts.
  if [ "$sys" = "Linux" ] && [ "$install_multi_user" = "false" ] && [ -d /nix/var/nix/db ] && [ ! -w /nix/var/nix/db ]; then
    log "Removing existing multi-user Nix installation..."
    sudo sh -c 'systemctl stop nix-daemon 2>/dev/null' || true
    sudo rm -rf /nix /etc/nix /etc/profile.d/nix-daemon.sh /etc/profile.d/nix.sh
  fi

  if ! command -v nix >/dev/null 2>&1; then
    if [ "$sys" = "Darwin" ]; then
      log "Installing multi-user Nix (Determinate)..."
      curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix \
        | sh -s -- install macos --no-confirm --determinate
      multiuser_source_env
      darwin_start_daemons
      if ! darwin_wait_daemon; then
        log "Daemon not ready; attempting repair..."
        darwin_repair_if_needed
        darwin_start_daemons
        if ! darwin_wait_daemon; then
          log "Nix daemon still not ready. Open a new terminal and rerun this script."
          exit 1
        fi
      fi
    else
      # Linux: prefer multi-user (daemon) when possible
      local install_flags=(--yes)
      if [ "$install_multi_user" = "true" ]; then
        log "Installing multi-user Nix..."
        install_flags+=(--daemon)
      else
        log "Installing single-user Nix..."
        install_flags+=(--no-daemon)
      fi
      sh <(curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install) "${install_flags[@]}"
      if [ "$install_multi_user" = "false" ]; then
        ensure_bwrap_if_needed
      fi
    fi
  fi

  if [ -f "$profile_sh" ]; then
    # shellcheck disable=SC1090
    . "$profile_sh"
  fi
  if [ -d "$HOME/.nix-profile/bin" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi

  # Ensure daemon-backed environment when available
  multiuser_source_env

  ensure_nix_features
  ensure_shell_inits
  register_login_shell

  # If we are on Linux and not using a daemon (no daemon socket),
  # assume single-user install and ensure bubblewrap is present.
  if [ "$sys" = "Linux" ] && [ ! -S /nix/var/nix/daemon-socket/socket ]; then
    ensure_bwrap_if_needed
  fi
}

ensure_repo() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "Updating existing repo at $DOTFILES_DIR..."
    git -C "$DOTFILES_DIR" fetch --all -q
    git -C "$DOTFILES_DIR" checkout -B main origin/main -q
    git -C "$DOTFILES_DIR" reset --hard origin/main -q
  else
    log "Cloning repo to $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

main() {
  log "Starting unified setup..."
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
  description = "Site-specific configuration for $RUN_USER@$HOST_NAME";
  outputs = { ... }: {
    homeModule = { ... }: {
      home.username = "$RUN_USER";
      home.homeDirectory = "$HOME";
      $ENABLE_SECRETS_LINE
    };
  };
}
EOF

  log "Activating Home Manager (#$OS_TARGET) with site override..."
  if [ "$OS_TARGET" = "darwin" ]; then
    NIX_ARGS=(--store daemon)
  else
    NIX_ARGS=()
  fi
  nix "${NIX_ARGS[@]}" run home-manager/master -- switch \
    --flake ".#$OS_TARGET" \
    --override-input site "path:$SITE_DIR"

  rm -rf "$SITE_DIR"

  register_login_shell
}

main "$@"
