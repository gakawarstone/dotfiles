{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/boot.nix
      ./modules/networking.nix
      ./modules/locale.nix
      ./modules/services.nix
      ./modules/user.nix
      ./modules/packages.nix
      ./modules/desktop/xfce.nix
      ./modules/dev/python.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05";
}
