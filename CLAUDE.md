# Dotfiles

Personal Nix Flakes + Home Manager cross-platform dotfiles. See README for full details.

## Notes

- Deploy with the `curl ... | bash` one-liner from the README. Exception: when already working inside the dotfiles repo and actively iterating on new features, run `bash scripts/setup.sh` directly — it applies the local working tree, whereas the one-liner clones a fresh copy from GitHub and therefore only deploys committed AND pushed changes. Never manually invoke `home-manager switch`, `darwin-rebuild`, or their underlying `nix run` commands — if a deploy fails, fix the cause and re-run `setup.sh` / the one-liner.
- Files managed by Home Manager are nix store symlinks (e.g. `~/.codex/config.toml`). `chmod` and direct writes will fail with `Operation not permitted`. To edit temporarily: `rm` the symlink and write a new file — the next deploy will restore it. To edit permanently: modify the template in `home/common.nix` and redeploy.
- `claude-instruction.md` is the source for the global `~/.claude/CLAUDE.md` (Code of Conduct). It must stay super general — behavior principles only, no project-specific or tool-specific technical details.

## Privacy audit — required before every commit

**This repository is PUBLIC.** Audit anything you add or edit, every time. Not only when it feels sensitive.

**The standard is aggregation, not any single line.** A detail that looks harmless alone still fails if it combines with the rest of the repo — or with what is already public elsewhere — to reveal something private. Judge each addition against everything else that is here, not on its own.

Reject, or rewrite generically:

- **Other people.** Names, usernames, home directories, machine names, anything that identifies a collaborator. Their privacy is not the author's to spend. `/home/<someone>/`, "a colleague", "two senior people he works with".
- **Unpublished work.** Real script names, flag names, dataset names, internal project codenames, venue or paper identifiers. Concrete examples make rules vivid and are exactly what leaks — write the mechanism, not the artifact.
- **Health, body, mood, personal life.** These do not belong in a public repo in any form, not even as an anonymous-looking illustration. Material of this kind goes in a private repo and is linked from here by name only.
- **Identifiers and org ties.** Non-public email addresses, account names, app/client IDs, hostnames, internal IPs, profile names that reveal which organizations the author works with.
- **Verbatim user quotes.** Paraphrase.

Worked examples are the highest-risk content in this repo: their whole purpose is specificity. Keep the failure chain, strip everything that identifies the incident.

When something must stay specific to be useful, it goes in a private repo and is referenced here by name — see the `personal-matters` skill, deliberately absent from `home/common.nix` for this reason.
