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

  config = lib.mkIf cfg.enableSecrets {
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

    # 2) Optional tokens (examples)
    # sops.secrets."tokens/claude" = {
    #   path = "${config.home.homeDirectory}/.config/claude/token";
    #   mode = "0600";
    # };
    # sops.secrets."tokens/openai" = {
    #   path = "${config.home.homeDirectory}/.config/openai/token";
    #   mode = "0600";
    # };
  };
}
