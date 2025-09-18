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
    # Site-specific configuration (can be overridden with --override-input)
    site.url = "path:./site-default";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, site, ... }:
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
        # Generic Linux configuration (uses site module for user/home)
        linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          modules = [
            sops-nix.homeManagerModules.sops
            ./home/common.nix
            ./home/secrets.nix
            ./home/linux.nix
          ] ++ (if site ? homeModule then [ site.homeModule ] else []);
        };

        # Generic macOS configuration (uses site module for user/home)
        darwin = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
          modules = [
            sops-nix.homeManagerModules.sops
            ./home/common.nix
            ./home/secrets.nix
            ./home/darwin.nix
          ] ++ (if site ? homeModule then [ site.homeModule ] else []);
        };
      };
    };
}
