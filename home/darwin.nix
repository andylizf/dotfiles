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

  # lark-cli is installed imperatively via npm (~/.local/bin/lark-cli -> run.js). Wrap it with a
  # pull-before-use shim so every invocation refreshes the token from Bitwarden first (keeps the
  # access token fresh, avoids lark-cli's delete-on-failed-refresh). Idempotent + survives npm
  # updates: a raw npm lark-cli (no wrapper marker) is moved aside to lark-cli.real, then the
  # wrapper is (re)installed.
  home.file.".local/bin/lark-cli-wrapper.sh" = {
    source = ./scripts/lark-cli-wrapper.sh;
    executable = true;
  };
  home.activation.installLarkCliWrapper = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    LARK="${config.home.homeDirectory}/.local/bin/lark-cli"
    REAL="${config.home.homeDirectory}/.local/bin/lark-cli.real"
    WRAP="${config.home.homeDirectory}/.local/bin/lark-cli-wrapper.sh"
    if [ -e "$LARK" ] && ! grep -q "pull-before-use wrapper" "$LARK" 2>/dev/null; then
      run mv -f "$LARK" "$REAL"
    fi
    if [ -e "$REAL" ] && [ -f "$WRAP" ]; then
      run cp -f "$WRAP" "$LARK"
      run chmod +x "$LARK"
    fi
  '';

  # bws (Bitwarden Secrets Manager CLI): the nixpkgs package fails to build, so fetch the
  # prebuilt binary to ~/.local/bin on first activation (idempotent).
  home.activation.installBws = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "${config.home.homeDirectory}/.local/bin/bws" ]; then
      run mkdir -p "${config.home.homeDirectory}/.local/bin"
      arch="$(uname -m)"
      case "$arch" in
        arm64) triple="aarch64-apple-darwin" ;;
        x86_64) triple="x86_64-apple-darwin" ;;
        *) triple="" ;;
      esac
      if [ -n "$triple" ]; then
        url="https://github.com/bitwarden/sdk-sm/releases/download/bws-v2.1.0/bws-$triple-2.1.0.zip"
        tmp="$(mktemp -d)"
        if ${pkgs.curl}/bin/curl -sL -o "$tmp/bws.zip" "$url" && ${pkgs.unzip}/bin/unzip -o "$tmp/bws.zip" -d "$tmp" >/dev/null 2>&1; then
          run mv -f "$tmp/bws" "${config.home.homeDirectory}/.local/bin/bws"
          run chmod +x "${config.home.homeDirectory}/.local/bin/bws"
          run xattr -d com.apple.quarantine "${config.home.homeDirectory}/.local/bin/bws" 2>/dev/null || true
        fi
        rm -rf "$tmp"
      fi
    fi
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
