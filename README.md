# dotfiles

My Nix + Home Manager setup. Auto-adapts to any machine.

## Setup (one command)

```bash
git clone https://github.com/andylizf/dotfiles
cd dotfiles
bash scripts/setup.sh
```

The script will:

- install Nix via the Zero to Nix installer if missing
- detect OS (Linux/macOS) and source the Nix environment in non-login shells
- auto-inject current USER/HOME via a temporary site flake (pure flakes; no `--impure`)
- activate Home Manager for this machine
- if `~/.config/sops/age/keys.txt` exists at setup time, secrets are enabled automatically; otherwise they are skipped so first‑run always succeeds

### Linux notes (multi-user Nix)

- On Linux, the setup script now prefers a multi-user (daemon) Nix install. This avoids bubblewrap/userns issues common on Ubuntu 24.04 and cloud VMs.
- The script auto-detects the daemon socket. If `/run/nix/daemon-socket/socket` exists, it sets `NIX_REMOTE=unix:///run/nix/daemon-socket/socket` to ensure the client talks to the correct socket.
- When Home Manager would overwrite existing files, the script passes `-b backup` so your originals are preserved with a `.backup` suffix.

If you previously used single-user Nix and hit errors like `/nix/store/.../bash: No such file or directory`, switch to multi-user with the installer, or enable user namespaces and install `bubblewrap`. The script will try to install `bubblewrap` automatically if it detects single-user mode.

### For secrets

```bash
# Copy age key from local to remote
cat ~/.config/sops/age/keys.txt  # on local
echo "YOUR_AGE_KEY" > ~/.config/sops/age/keys.txt  # on remote
```

## What's included

- Packages: fish, git, unzip, tree, rsync, gh (GitHub CLI), uv, nodejs_22
- Git config: user, email, push/pull defaults, default branch, editor, colors
- Fish config: PATH via Home Manager, `CLAUDE_CODE_USE_VERTEX=1`

## SkyPilot

```bash
sky launch -c dev-machine skypilot/sky-dotfiles-gcp.yaml -y
# Cursor Remote
cursor --remote ssh-remote+dev-machine sky_workdir
# VS Code Remote
code --remote ssh-remote+dev-machine sky_workdir
```

## Secrets (sops-nix)

We use sops-nix to encrypt/decrypt secrets.

The initialization should only be run once on the local machine to generate the age key `~/.config/sops/age/keys.txt`.

```bash
# Initialize keys locally (once)
bash scripts/sops-init.sh

# Edit encrypted file (use Cursor or VS Code)
export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt
SOPS_EDITOR="cursor --wait" sops secrets/secrets.yaml
# or
SOPS_EDITOR="code --wait" sops secrets/secrets.yaml
```
