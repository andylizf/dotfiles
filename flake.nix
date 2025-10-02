{
  description = "Andy Lee's dotfiles with Nix Flakes + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    site.url = "path:./site-default";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, sops-nix, site, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { system, ... }: { };  # placeholders for future dev envs

      flake = let
        mkHome = { system, extraModules ? [ ] }:
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = baseModules ++ extraModules ++ siteModules;
          };

        baseModules = [
          sops-nix.homeManagerModules.sops
          ./home/common.nix
          ./home/secrets.nix
        ];

        siteModules = if site ? homeModule then [ site.homeModule ] else [];
      in {
        homeConfigurations = let
          linuxModules = [ ./home/linux.nix ];
          darwinModules = [ ./home/darwin.nix ];
          linuxConfig = mkHome { system = "x86_64-linux"; extraModules = linuxModules; };
          darwinConfig = mkHome { system = "aarch64-darwin"; extraModules = darwinModules; };
        in {
          linux = linuxConfig;
          "ubuntu-linux" = linuxConfig;
          darwin = darwinConfig;
        };
      };
    };
}
