{ config, pkgs, lib, ... }:
let
  home = config.home.homeDirectory;
  user = config.home.username;
  # The always-on writer host (mac-mini): holds the SOLE lark-cli refresh chain. Everything is
  # hostname-gated at activation time (scutil --get LocalHostName):
  #   writer  → refresh+publish agent; uses the unwrapped real CLI to actually refresh.
  #   readers → env-injection wrapper only (NO agent): on use it fetches the published access-token
  #             string from Bitwarden and injects it via LARKSUITE_CLI_USER_ACCESS_TOKEN, so a reader
  #             never holds a refresh_token and can never break the writer's single-use refresh chain.
  writerHost = "zhifei-clawhouse";
in
{
  # macOS-specific home-manager config.
  # System-level settings (Finder, Dock, Homebrew) are in system/darwin.nix via nix-darwin.

  # ---- lark-cli multi-machine token relay (via Bitwarden Secrets Manager) ----
  # Scripts deployed everywhere (harmless); the launchd agent + wrapper are hostname-gated below.
  home.file.".local/bin/lark-cli-wrapper.sh"    = { source = ./scripts/lark-cli-wrapper.sh;    executable = true; };
  home.file.".local/bin/lark-refresh.sh"        = { source = ./scripts/lark-refresh.sh;        executable = true; };
  home.file.".local/bin/lark-publish-tokens.sh" = { source = ./scripts/lark-publish-tokens.sh; executable = true; };
  home.file.".local/bin/lark-extract-ats.py"    = { source = ./scripts/lark-extract-ats.py;    executable = true; };

  home.activation.ensureLarkSyncDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${home}/.config/lark-sync"
  '';

  # bws (Bitwarden Secrets Manager CLI): nixpkgs package fails to build, so fetch the prebuilt
  # binary to ~/.local/bin on first activation (idempotent). Needed by both readers and writer.
  home.activation.installBws = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "${home}/.local/bin/bws" ]; then
      run mkdir -p "${home}/.local/bin"
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
          run mv -f "$tmp/bws" "${home}/.local/bin/bws"
          run chmod +x "${home}/.local/bin/bws"
          run xattr -d com.apple.quarantine "${home}/.local/bin/bws" 2>/dev/null || true
        fi
        rm -rf "$tmp"
      fi
    fi
  '';

  # Hostname-gated role setup: pick writer vs reader and install the right launchd agent + wrapper.
  home.activation.larkSyncRole = lib.hm.dag.entryAfter [ "linkGeneration" "installBws" "ensureLarkSyncDir" ] ''
    BIN="${home}/.local/bin"
    LA="${home}/Library/LaunchAgents"
    CFG="${home}/.config/lark-sync"
    UIDNUM="$(/usr/bin/id -u)"
    HOSTLOCAL="$(/usr/sbin/scutil --get LocalHostName 2>/dev/null || echo unknown)"
    PULL_PLIST="$LA/local.lark-sync-pull.plist"
    REFRESH_PLIST="$LA/local.lark-refresh.plist"
    AGENT_PATH="/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:$BIN"
    run mkdir -p "$LA" "$CFG"

    # Retire any lingering pull agent from the old (file-relay) design — readers no longer poll.
    /bin/launchctl bootout "gui/$UIDNUM/org.nix-community.home.lark-sync-pull" 2>/dev/null || true
    /bin/launchctl bootout "gui/$UIDNUM/local.lark-sync-pull" 2>/dev/null || true
    run rm -f "$PULL_PLIST"

    install_wrapper() {
      # Preserve the real npm binary as lark-cli.real, then install the env-injection wrapper over
      # lark-cli. Any wrapper (old or new) is a bash script referencing "lark-cli.real"; the real
      # node binary never does — so this safely upgrades the old wrapper without clobbering the real
      # binary, and also re-wraps after an npm reinstall replaces lark-cli with the node binary.
      if [ -e "$BIN/lark-cli" ] && ! grep -q 'lark-cli\.real' "$BIN/lark-cli" 2>/dev/null; then
        run mv -f "$BIN/lark-cli" "$BIN/lark-cli.real"
      fi
      if [ -e "$BIN/lark-cli.real" ] && [ -f "$BIN/lark-cli-wrapper.sh" ]; then
        run cp -f "$BIN/lark-cli-wrapper.sh" "$BIN/lark-cli"
        run chmod +x "$BIN/lark-cli"
      fi
    }
    remove_wrapper() {
      # Restore the real lark-cli binary (writer must use the unwrapped CLI to actually refresh).
      if [ -e "$BIN/lark-cli" ] && grep -q 'lark-cli\.real' "$BIN/lark-cli" 2>/dev/null \
         && [ -e "$BIN/lark-cli.real" ]; then
        run mv -f "$BIN/lark-cli.real" "$BIN/lark-cli"
      fi
    }

    if [ "$HOSTLOCAL" = "${writerHost}" ]; then
      # ---- WRITER (mac-mini) ----
      remove_wrapper
      cat > "$REFRESH_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.lark-refresh</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$BIN/lark-refresh.sh</string></array>
  <!-- 10min: lark-cli refreshes a token only once it has EXPIRED (no proactive/forced refresh), so
       this interval bounds how long an expired token can sit in Bitwarden before the agent rotates
       and republishes it. Rotation happens ~every 2h (on expiry), so a short interval adds no extra
       token invalidations — it only shrinks the reader-visible expiry gap. -->
  <key>StartInterval</key><integer>600</integer>
  <key>StandardOutPath</key><string>$CFG/refresh-stdout.log</string>
  <key>StandardErrorPath</key><string>$CFG/refresh-stderr.log</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$AGENT_PATH</string></dict>
</dict></plist>
PLIST
      /bin/launchctl bootout "gui/$UIDNUM/local.lark-refresh" 2>/dev/null || true
      /bin/launchctl bootstrap "gui/$UIDNUM" "$REFRESH_PLIST" 2>/dev/null || true
      echo "[lark-sync] role=writer ($HOSTLOCAL)"
    else
      # ---- READER ----
      /bin/launchctl bootout "gui/$UIDNUM/local.lark-refresh" 2>/dev/null || true
      run rm -f "$REFRESH_PLIST"
      install_wrapper
      echo "[lark-sync] role=reader ($HOSTLOCAL)"
    fi
  '';
}
