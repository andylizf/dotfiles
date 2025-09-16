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

You can also run Home Manager directly once Nix is installed:

```
# macOS
home-manager switch --flake .#andyl-darwin

# Linux
home-manager switch --flake .#andyl-linux
```

If fish doesn’t become your login shell automatically, set it manually:

```
chsh -s "$(command -v fish)"
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

Adjust system/username/home path if your host differs (e.g. Intel mac use `x86_64-darwin`).

## Notes

- State version is set to the matching Home Manager release. Update intentionally to opt-in to changed defaults.
- Keep the bootstrap minimal; let Nix/Home Manager do the rest.
- Avoid storing secrets in this repo.
