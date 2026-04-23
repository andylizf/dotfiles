{ pkgs, ... }:
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
}
