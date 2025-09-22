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
cursor --remote ssh-remote+dev-machine sky_workdir
```

## Secrets (sops-nix)

We use sops-nix to encrypt/decrypt secrets.

The initialization should only be run once on the local machine to generate the age key `~/.config/sops/age/keys.txt`.

```bash
# Initialize keys locally (once)
bash scripts/sops-init.sh

# Edit encrypted file
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
SOPS_EDITOR="cursor --wait" sops secrets/secrets.yaml
```
