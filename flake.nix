{
  description = "Andy Lee's dotfiles with Nix Flakes + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    site.url = "path:./site-default";

    system-manager.url = "github:numtide/system-manager";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, sops-nix, site, system-manager, flake-parts, ... }:
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

        darwinUser = if site ? darwinUser then site.darwinUser else "andyl";
        darwinHome = if site ? darwinHome then site.darwinHome else "/Users/${darwinUser}";
        darwinEnableSecrets = if site ? darwinEnableSecrets then site.darwinEnableSecrets else false;
      in {
        systemConfigs.default = system-manager.lib.makeSystemConfig {
          modules = [ ./system ];
        };

        darwinConfigurations.default = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./system/darwin.nix
            home-manager.darwinModules.home-manager
            {
              system.stateVersion = 6;
              system.primaryUser = darwinUser;
              nixpkgs.config.allowUnfree = true;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              users.users.${darwinUser}.home = darwinHome;
              home-manager.users.${darwinUser} = {
                imports = baseModules ++ [ ./home/darwin.nix ];
                home.username = darwinUser;
                home.homeDirectory = darwinHome;
                dotfiles.enableSecrets = darwinEnableSecrets;
              };
            }
          ];
        };

        homeConfigurations = let
          linuxModules = [ ./home/linux.nix ];
          linuxConfig = mkHome { system = "x86_64-linux"; extraModules = linuxModules; };
        in {
          linux = linuxConfig;
          "ubuntu-linux" = linuxConfig;
        };
      };
    };
}
