{
  description = "Andy Lee's dotfiles with Nix Flakes + Home Manager";

  inputs = {
    # Track latest unstable for freshest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Use latest Home Manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Secrets management for Home Manager
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
    let
      mkHome = { system, username, homeDirectory, modules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
          modules = [
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
            # Enable sops-nix Home Manager module (secrets support)
            sops-nix.homeManagerModules.sops
            ./home/common.nix
            ./home/secrets.nix
          ] ++ modules;
        };
    in
    {
      homeConfigurations = {
        # Auto-detect user Linux (x86_64)
        user-linux = mkHome {
          system = "x86_64-linux";
          username = builtins.getEnv "USER";
          homeDirectory = builtins.getEnv "HOME";
          modules = [ ./home/linux.nix ];
        };

        # Auto-detect user macOS (Apple Silicon). If on Intel mac, switch to x86_64-darwin.
        user-darwin = mkHome {
          system = "aarch64-darwin";
          username = builtins.getEnv "USER";
          homeDirectory = builtins.getEnv "HOME";
          modules = [ ./home/darwin.nix ];
        };
      };
    };
}
