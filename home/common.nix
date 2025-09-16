{ pkgs, lib, ... }:
{
  # Set once and bump intentionally when adopting changed defaults.
  home.stateVersion = "24.05";

  # Core packages common to Linux and macOS
  home.packages = with pkgs; [
    fish
    git
    unzip
    tree
    rsync
    gh
    uv
    nodejs_22
  ];

  # Ensure ~/.local/bin is in PATH for user-managed tools if needed
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.fish = {
    enable = true;
    shellInit = ''
      # Claude Code env flag you requested
      set -gx CLAUDE_CODE_USE_VERTEX 1

      # Ensure npm global bin (~/.local/bin) is in PATH for fish.
      # fish_add_path exists since fish 3.2 and is idempotent; it
      # stores ~/.local/bin in the universal fish_user_paths.
      fish_add_path ~/.local/bin
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

  # Optional: set npm global prefix to ~/.local (safer PATH)
  home.activation.npmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v npm >/dev/null 2>&1; then
      npm config set prefix "$HOME/.local" --global || true
      mkdir -p "$HOME/.local/bin"
    fi
  '';


  # Install/update CLI tools from npm to ~/.local on each switch.
  # This keeps them tracking npm latest while remaining user-scoped.
  home.activation.installDevCLIs = lib.hm.dag.entryAfter [ "npmPrefix" ] ''
    set -e
    export npm_config_prefix="$HOME/.local"
    export PATH="$HOME/.local/bin:$PATH"
    NPM="${pkgs.nodejs_22}/bin/npm"
    # Always try to install/upgrade to latest; ignore failures to avoid
    # blocking the rest of the HM switch if npm registry is temporarily down.
    "$NPM" i -g @anthropic-ai/claude-code@latest @openai/codex@latest || true
  '';

  # Configure Claude Code if installed (no-op if missing)
  home.activation.claudeConfig = lib.hm.dag.entryAfter [ "installDevCLIs" ] ''
    if command -v claude >/dev/null 2>&1; then
      claude config set --global preferredNotifChannel terminal_bell || true
    fi
  '';
}
