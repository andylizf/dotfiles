{ pkgs, ... }:
let
  # Codex trusts lifecycle hooks delivered through managed requirements. Keeping the
  # executable in this immutable Nix output makes the policy target exact and reviewable.
  omemManagedHook = pkgs.writeShellScriptBin "omem-managed-hook" ''
    set -u

    event="''${1:-}"
    export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    export OMEM_MODE="''${OMEM_MODE:-full}"
    export OMEM_MEMORY_MODE="''${OMEM_MEMORY_MODE:-index}"
    export OMEM_RUNNER=codex
    export OMEM_ROOT="''${OMEM_ROOT:-$HOME/omem-data}"
    export OMEM_TRANSCRIPTS="''${OMEM_TRANSCRIPTS:-$HOME/omem-transcripts}"

    omem_bin="$HOME/.local/bin/omem"
    if [ ! -x "$omem_bin" ]; then
      case "$event" in
        stash|extract) printf '{}\n' ;;
      esac
      exit 0
    fi

    case "$event" in
      observe-write|publish-write) exec "$omem_bin" hook "$event" ;;
      session-start) exec "$omem_bin" hook session-start ;;
      recall) exec "$omem_bin" hook recall ;;
      stash|extract)
        "$omem_bin" hook "$event"
        printf '{}\n'
        ;;
      *) exit 2 ;;
    esac
  '';
in
{
  # Don't let nix-darwin manage nix.conf — Determinate Nix owns it.
  nix.enable = false;

  system.defaults = {
    finder.ShowPathbar = true;

    dock.autohide = true;
    dock.tilesize = 54;

    NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
    };
    casks = [
    ];
    brews = [
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  # Managed hooks are trusted by policy in the CLI, desktop app, and IDE. We
  # intentionally do not set allow_managed_hooks_only: unrelated user/project/plugin
  # hooks should keep working and retain Codex's normal per-definition trust review.
  environment.etc."codex/requirements.toml".text = ''
    [features]
    hooks = true

    [hooks]
    managed_dir = "${omemManagedHook}/bin"

    [[hooks.PreToolUse]]
    matcher = "apply_patch"
    [[hooks.PreToolUse.hooks]]
    type = "command"
    command = "${omemManagedHook}/bin/omem-managed-hook observe-write"

    [[hooks.SessionStart]]
    [[hooks.SessionStart.hooks]]
    type = "command"
    command = "${omemManagedHook}/bin/omem-managed-hook session-start"
    additionalContextLimit = 16000
    statusMessage = "Loading shared omem context"

    [[hooks.UserPromptSubmit]]
    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "${omemManagedHook}/bin/omem-managed-hook recall"
    additionalContextLimit = 5000

    # The publication sidecar is deliberately write-only and fail-open. It receives
    # the exact apply_patch path set, never injects context, and never changes the host
    # tool result. Recall/hybrid adds a separate explicit delivery profile; index mode
    # has no all-tools PostToolUse callback.
    [[hooks.PostToolUse]]
    matcher = "apply_patch"
    [[hooks.PostToolUse.hooks]]
    type = "command"
    command = "${omemManagedHook}/bin/omem-managed-hook publish-write"

    [[hooks.Stop]]
    [[hooks.Stop.hooks]]
    type = "command"
    command = "${omemManagedHook}/bin/omem-managed-hook stash"
    timeout = 90
    statusMessage = "Archiving Codex session to omem"

    [[hooks.Stop.hooks]]
    type = "command"
    command = "${omemManagedHook}/bin/omem-managed-hook extract"
    timeout = 30
    statusMessage = "Extracting durable omem memory"
  '';
}
