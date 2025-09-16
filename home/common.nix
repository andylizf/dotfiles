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
    # Set fish as login shell where supported; may still require manual chsh.
    setLoginShell = true;
    shellInit = ''
      # Claude Code env flag you requested
      set -gx CLAUDE_CODE_USE_VERTEX 1
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

  # Example: configure Claude Code if it's installed via npm (no-op if missing)
  home.activation.claudeConfig = lib.hm.dag.entryAfter [ "npmPrefix" ] ''
    if command -v claude >/dev/null 2>&1; then
      claude config set --global preferredNotifChannel terminal_bell || true
    fi
  '';
}
