# dotfiles

My Nix + Home Manager setup. Auto-adapts to any machine.

## Setup

```bash
git clone https://github.com/andylizf/dotfiles
cd dotfiles
./bootstrap.sh
```

Installs Nix via [Zero to Nix](https://zero-to-nix.com/) and auto-configures for current user/OS.

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

We use sops-nix to encrypt and decrypt secrets. The initialization should only be run once on the local machine to generate the age key `~/.config/sops/age/keys.txt`.

```bash
# Initialize
bash scripts/sops-init.sh

# Edit
SOPS_EDITOR="cursor --wait" sops secrets/secrets.yaml
```
