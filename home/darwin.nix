{ config, pkgs, lib, ... }:
{
  # macOS-specific home-manager config.
  # System-level settings (Finder, Dock, Homebrew) are in system/darwin.nix via nix-darwin.

  # lark-cli token relay (reader side).
  # The always-on writer (mac-mini) refreshes lark-cli tokens daily and uploads them to
  # Bitwarden Secrets Manager. This machine pulls them on login/wake + every 6h, so a
  # machine that was off for weeks gets valid tokens without a browser re-auth.
  # Bootstrap secret (BWS_ACCESS_TOKEN) comes from sops → ~/.config/lark-sync/bws-token.

  home.file.".local/bin/lark-sync-pull.sh" = {
    source = ./scripts/lark-sync-pull.sh;
    executable = true;
  };

  home.activation.ensureLarkSyncDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.config/lark-sync"
  '';

  launchd.agents.lark-sync-pull = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/bash"
        "${config.home.homeDirectory}/.local/bin/lark-sync-pull.sh"
      ];
      RunAtLoad = true;
      StartInterval = 21600; # every 6h; missed intervals fire on wake
      StandardOutPath = "${config.home.homeDirectory}/.config/lark-sync/launchd-stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/.config/lark-sync/launchd-stderr.log";
      EnvironmentVariables = {
        PATH = "/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin:${config.home.homeDirectory}/.local/bin";
      };
    };
  };
}
