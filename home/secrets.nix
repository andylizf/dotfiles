{ config, ... }:
{
  # Use sops-nix to decrypt secret files to user directory.
  # Convention: encrypted files are in ../secrets/secrets.yaml
  # Local age private key is in ~/.config/sops/age/keys.txt (not in repo).

  sops.defaultSopsFile = ./../secrets/secrets.yaml;
  # Alternatively, use ssh private key: sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # Map secrets to disk paths (add/remove as needed).
  # 1) SSH private key (mode 0600)
  sops.secrets."ssh/id_ed25519" = {
    path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    mode = "0600";
  };

  # 2) Optional: Claude/Codex API Token (example; delete if not needed)
  # sops.secrets."tokens/claude" = {
  #   path = "${config.home.homeDirectory}/.config/claude/token";
  #   mode = "0600";
  # };
  # sops.secrets."tokens/openai" = {
  #   path = "${config.home.homeDirectory}/.config/openai/token";
  #   mode = "0600";
  # };
}

