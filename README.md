# dotfiles (Nix Flakes + Home Manager)

Personal, reproducible machine setup for Linux and macOS using Nix Flakes + Home Manager. Bootstrap script included.

## Usage

1) Install Nix (if missing) and activate this config with the bootstrap script:

```
git clone https://github.com/andylizf/dotfiles
cd dotfiles
./bootstrap.sh
```

This installs Nix if needed and runs Home Manager with the matching flake target for your OS:
- `#andyl-darwin` on macOS (Apple Silicon by default)
- `#andyl-linux` on Linux (x86_64)
- `#gcpuser-linux` on SkyPilot GCP default user 'gcpuser'

You can also run Home Manager directly once Nix is installed:

```
# macOS
nix profile add github:nix-community/home-manager
home-manager switch --flake .#andyl-darwin

# Linux
home-manager switch --flake .#andyl-linux
```

## What’s included

- Packages: fish, git, unzip, tree, rsync, gh (GitHub CLI), uv, nodejs_22
- Git config: user, email, push/pull defaults, default branch, editor, colors
- Fish config: PATH via Home Manager, `CLAUDE_CODE_USE_VERTEX=1`

Note: global npm installs (e.g. CLI tools) are better managed per project or as Nix packages. If you still prefer global npm, use `~/.local` prefix (already configured) and consider `home.activation` hooks carefully.

## SSH keys (safe setup)

Do NOT commit private keys. Generate locally and optionally upload using GitHub CLI:

```
./scripts/setup-ssh.sh  # generates ed25519 key and uploads via gh
```

Alternatively, manage secrets with 1Password CLI or sops-nix/agenix.

## Systems

`flake.nix` includes two targets:
- `andyl-darwin`  -> `aarch64-darwin`, home at `/Users/andyl`
- `andyl-linux`   -> `x86_64-linux`,  home at `/home/andyl`
- `gcpuser-linux` -> `x86_64-linux`,  home at `/home/gcpuser`

Adjust system/username/home path if your host differs (e.g. Intel mac use `x86_64-darwin`).

## SkyPilot

```
sky launch -c dev-machine skypilot/sky-dotfiles-gcp.yaml -y
```

After that, we can SSH into the machine and run:
```
cursor --remote ssh-remote+dev-machine sky_workdir
```


## Notes

- State version is set to the matching Home Manager release. Update intentionally to opt-in to changed defaults.
- Keep the bootstrap minimal; let Nix/Home Manager do the rest.

## Secrets Management (sops-nix)

This repo has integrated sops-nix, which is used to decrypt and send secret files (e.g. `~/.ssh/id_ed25519`) under Home Manager.

Quick start:
- Install tools (locally)
    - `nix profile add nixpkgs#age nixpkgs#sops`
- Initialize once (auto‑generates age key if missing)
    - `bash scripts/sops-init.sh`
    - This creates .sops.yaml (using your age public key) and encrypts secrets/secrets.example.yaml to secrets/secrets.yaml
- Edit secrets
    - `SOPS_EDITOR="cursor --wait" sops secrets/secrets.yaml`
- Commit/push (encrypted only)
    - `git add secrets/secrets.yaml .sops.yaml`
    - git commit -m "chore(secrets): add encrypted secrets"
    - git push
- Remote setup (to decrypt on the VM)
    - Copy your local ~/.config/sops/age/keys.txt to the VM at the same path
    - `cd ~/dotfiles && nix run home-manager/master -- switch --flake .#gcpuser-linux`
- Files created by Home Manager (see home/secrets.nix)
    - ssh/id_ed25519 -> ~/.ssh/id_ed25519 (0600)
    - Add other tokens under tokens/* as needed

Notes:
- Do not commit plaintext secrets or local age private keys; the repo only commits the encrypted `secrets/secrets.yaml`.
- Remote machines need to place the decrypted age private key in `~/.config/sops/age/keys.txt` to switch smoothly.
