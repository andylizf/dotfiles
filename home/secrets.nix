{ config, lib, ... }:
let
  cfg = config.dotfiles;
in
{
  options.dotfiles.enableSecrets = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable sops-nix secrets management for this user.";
  };

  config = lib.mkIf cfg.enableSecrets (let
    sopsExec = lib.attrByPath [ "systemd" "user" "services" "sops-nix" "Service" "ExecStart" ] null config;
    systemctlPathOrNull = lib.attrByPath [ "systemd" "user" "systemctlPath" ] null config;
    systemctlCheckSnippet =
      if systemctlPathOrNull != null then ''
        if [ -x ${systemctlPathOrNull} ]; then
          ${systemctlPathOrNull} --user is-system-running >/dev/null 2>&1
        else
          false
        fi
      '' else ''
        if command -v systemctl >/dev/null 2>&1; then
          systemctl --user is-system-running >/dev/null 2>&1
        else
          false
        fi
      '';
  in {
    # Use sops-nix to decrypt secret files to user directory.
    # Convention: encrypted files are in ../secrets/secrets.yaml
    # Age private key expected at ~/.config/sops/age/keys.txt
    sops.defaultSopsFile = ./../secrets/secrets.yaml;
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Map secrets to disk paths (add/remove as needed).
    # 1) SSH private key (mode 0600)
    sops.secrets."ssh/id_ed25519" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
    };

    # 2) GCP ADC credentials for local tooling (optional)
    sops.secrets."gcloud/application_default_credentials" = {
      path = "${config.home.homeDirectory}/.config/gcloud/application_default_credentials.json";
      mode = "0600";
    };

    # 3) AWS credentials/config (optional)
    sops.secrets."aws/credentials" = {
      path = "${config.home.homeDirectory}/.aws/credentials";
      mode = "0600";
    };
    sops.secrets."aws/config" = {
      path = "${config.home.homeDirectory}/.aws/config";
      mode = "0600";
    };

    # 4) GitHub credential store (Personal Access Token, etc.)
    sops.secrets."github/git-credentials" = {
      path = "${config.home.homeDirectory}/.git-credentials";
      mode = "0600";
    };

    # 5) GitHub CLI auth config (hosts.yml)
    sops.secrets."github/gh-hosts" = {
      path = "${config.home.homeDirectory}/.config/gh/hosts.yml";
      mode = "0600";
    };

    # 6) Hugging Face CLI token (used for HF_TOKEN)
    sops.secrets."huggingface/token" = {
      path = "${config.home.homeDirectory}/.config/huggingface/token";
      mode = "0600";
    };

    # 7) Gemini API token (used for GOOGLE_API_KEY / GEMINI_API_KEY)
    sops.secrets."tokens/gemini" = {
      path = "${config.home.homeDirectory}/.config/gemini/token";
      mode = "0600";
    };

    # 8) Anthropic API key (used for ANTHROPIC_API_KEY)
    sops.secrets."tokens/claude" = {
      path = "${config.home.homeDirectory}/.config/anthropic/token";
      mode = "0600";
    };

    # 9) Overleaf Git token (used for HTTPS remotes)
    sops.secrets."overleaf/git-token" = {
      path = "${config.home.homeDirectory}/.config/overleaf/git-token";
      mode = "0600";
    };

    # 10) Docker registry credentials (~/.docker/config.json)
    sops.secrets."docker/config.json" = {
      path = "${config.home.homeDirectory}/.docker/config.json";
      mode = "0600";
    };

    # 2) Optional tokens (examples)
    # sops.secrets."tokens/claude" = {
    #   path = "${config.home.homeDirectory}/.config/claude/token";
    #   mode = "0600";
    # };
    # sops.secrets."tokens/openai" = {
    #   path = "${config.home.homeDirectory}/.config/openai/token";
    #   mode = "0600";
    # };
    home.activation.sopsManualSync = lib.mkIf (sopsExec != null)
      (lib.hm.dag.entryAfter [ "sops-nix" ] ''
        if ! (
          ${systemctlCheckSnippet}
        ); then
          echo "[dotfiles] user systemd unavailable; installing secrets via sops-nix manually"
          if [ -z "''${XDG_RUNTIME_DIR:-}" ]; then
            export XDG_RUNTIME_DIR="''${HOME}/.local/run"
            mkdir -p "''${XDG_RUNTIME_DIR}"
            chmod 700 "''${XDG_RUNTIME_DIR}" || true
          fi
          ${sopsExec}
        fi
      '');
  });
}
