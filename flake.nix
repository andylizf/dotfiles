{
  description = "Andy Lee's dotfiles with Nix Flakes + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      mkHome = { system, username, homeDirectory, modules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          modules = [
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
            ./home/common.nix
          ] ++ modules;
        };
    in
    {
      homeConfigurations = {
        # Linux (x86_64)
        andyl-linux = mkHome {
          system = "x86_64-linux";
          username = "andyl";
          homeDirectory = "/home/andyl";
          modules = [ ./home/linux.nix ];
        };

        # Linux (x86_64) for cloud VMs with default user 'ubuntu'
        ubuntu-linux = mkHome {
          system = "x86_64-linux";
          username = "ubuntu";
          homeDirectory = "/home/ubuntu";
          modules = [ ./home/linux.nix ];
        };

        # Linux (x86_64) for SkyPilot GCP default user 'gcpuser'
        gcpuser-linux = mkHome {
          system = "x86_64-linux";
          username = "gcpuser";
          homeDirectory = "/home/gcpuser";
          modules = [ ./home/linux.nix ];
        };

        # macOS (Apple Silicon). If on Intel mac, switch to x86_64-darwin.
        andyl-darwin = mkHome {
          system = "aarch64-darwin";
          username = "andyl";
          homeDirectory = "/Users/andyl";
          modules = [ ./home/darwin.nix ];
        };
      };
    };
}
