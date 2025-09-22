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
