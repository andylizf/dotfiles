# Dotfiles

Personal Nix Flakes + Home Manager cross-platform dotfiles. See README for full details.

## Notes

- Deploy with the `curl ... | bash` one-liner from the README. Do not run `setup.sh` directly (unless developing the dotfiles themselves), and never manually invoke `home-manager switch` or `darwin-rebuild`.
- Files managed by Home Manager are nix store symlinks (e.g. `~/.codex/config.toml`). `chmod` and direct writes will fail with `Operation not permitted`. To edit temporarily: `rm` the symlink and write a new file — the next deploy will restore it. To edit permanently: modify the template in `home/common.nix` and redeploy.
