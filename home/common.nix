{ pkgs, lib, ... }:
{
  # Set once and bump intentionally when adopting changed defaults.
  home.stateVersion = "24.05";

  # Core packages common to Linux and macOS
  home.packages = with pkgs; [
    awscli2
    google-cloud-sdk
    fish
    git
    unzip
    gnutar
    gzip
    tree
    rsync
    gh
    uv
    nodejs_22
    direnv
  ];

  # Ensure ~/.local/bin is in PATH for user-managed tools if needed
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.fish = {
    enable = true;
    shellInit = ''
      # Claude Code env flags
      set -gx CLAUDE_CODE_USE_VERTEX 1
      set -gx ANTHROPIC_VERTEX_PROJECT_ID llm-retrieval-403823

      # Direnv integration for fish
      if command -v direnv >/dev/null 2>&1
        direnv hook fish | source
      end

      # Ensure npm global bin (~/.local/bin) is in PATH for fish.
      # fish_add_path exists since fish 3.2 and is idempotent; it
      # stores ~/.local/bin in the universal fish_user_paths.
      fish_add_path ~/.local/bin

      # Ensure Nix profile binaries are available to shebangs like `#!/usr/bin/env node`
      # Source fish integration if present, then force-add common Nix profile paths
      if test -f ~/.nix-profile/etc/profile.d/nix.fish
        . ~/.nix-profile/etc/profile.d/nix.fish
      end
      fish_add_path ~/.nix-profile/bin
      fish_add_path ~/.local/state/nix/profile/bin

      # First-login init: set Claude Code notif channel once (idempotent)
      if status --is-interactive
        if test -x ~/.local/bin/claude; and not test -e ~/.local/state/claude/prefs_set
          ~/.local/bin/claude config set -g preferredNotifChannel terminal_bell; or true
          mkdir -p ~/.local/state/claude
          touch ~/.local/state/claude/prefs_set
        end
      end
    '';
  };

  programs.git = {
    enable = true;
    userName = "Andy Lee";
    userEmail = "andylizf@outlook.com";
    extraConfig = {
      push.autoSetupRemote = true;
      push.default = "current";
      branch.autoSetupMerge = false;
      init.defaultBranch = "main";
      credential.helper = "store";
      core.editor = "cursor --wait";
      pull.rebase = true;
      rebase.autoStash = true;
      color.ui = "auto";
    };
  };


  home.activation.fixSshPerms = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh" || true
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys" || true
    PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp3Vontmq0bBIlnQIeUFqk/UhwGSFm3f96MRdR2T6AQ andylizf@outlook.com'
    if ! grep -Fxq "$PUBKEY" "$HOME/.ssh/authorized_keys"; then
      printf '%s\n' "$PUBKEY" >> "$HOME/.ssh/authorized_keys"
    fi
  '';

  # Optional: set npm global prefix to ~/.local (safer PATH)
  home.activation.npmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v npm >/dev/null 2>&1; then
      npm config set prefix "$HOME/.local" --global || true
      mkdir -p "$HOME/.local/bin"
    fi
  '';

  home.activation.ensureGcloudDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/gcloud"
    chmod 700 "$HOME/.config/gcloud" || true
  '';

  home.activation.ensureAwsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.aws"
    chmod 700 "$HOME/.aws" || true
  '';

  home.file.".claude/settings.json".text = ''
    {
      "$schema": "https://json.schemastore.org/claude-code-settings.json",
      "includeCoAuthoredBy": false,
      "permissions": {
        "allow": [
          "Bash(grep:*)",
          "Read(*)",
          "Bash(gh pr diff:*)",
          "Bash(git pr diff view:*)",
          "Bash(git pr view:*)",
          "Bash(git pr review:*)",
          "Bash(git pr list:*)",
          "Bash(git pr describe:*)",
          "Bash(gh issue view:*)",
          "Bash(git log:*)",
          "Bash(git rev-parse:*)",
          "Bash(ls:*)",
          "Bash(pwd:*)",
          "Bash(cat:*)",
          "Bash(aws s3 ls:*)",
          "Bash(gsutil ls:*)",
          "Bash(s5cmd ls:*)",
          "Bash(du:*)",
          "Bash(gh api repos/skypilot-org/skypilot/issues:*)",
          "Bash(sleep:*)",
          "Bash(sky status:*)",
          "Bash(sky queue:*)",
          "Bash(sky logs:*)",
          "Bash(sky jobs logs:*)",
          "Bash(sky jobs status:*)",
          "Bash(sky serve status:*)",
          "Bash(sky serve logs:*)",
          "Bash(sky api status:*)",
          "Bash(sky api info:*)",
          "Bash(sky api logs:*)"
        ]
      },
      "model": "opus",
      "gitAttribution": false
    }
  '';

  # Install/update CLI tools from npm to ~/.local on each switch.
  # Keep tracking npm latest while remaining user-scoped.
  home.activation.installDevCLIs = lib.hm.dag.entryAfter [ "npmPrefix" ] ''
    set -e
    # Ensure user-level prefix and directories exist
    export npm_config_prefix="$HOME/.local"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/lib/node_modules"
    # Make sure node (from nix) is on PATH for npm lifecycle scripts
    export PATH="${pkgs.nodejs_22}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$HOME/.local/bin:$PATH"
    export TAR="${pkgs.gnutar}/bin/tar"
    NPM="${pkgs.nodejs_22}/bin/npm"
    # Install each CLI independently so one failing postinstall doesn't block the other
    "$NPM" i -g @anthropic-ai/claude-code@latest || true
    "$NPM" i -g @openai/codex@latest || true
  '';

  home.file.".codex/config.toml".text = ''
    # Managed by Home Manager — local changes will be overwritten.
    [tools]
    web_search = true

    [mcp_servers.context7]
    command = "npx"
    args = ["-y", "@upstash/context7-mcp"]
  '';

}
