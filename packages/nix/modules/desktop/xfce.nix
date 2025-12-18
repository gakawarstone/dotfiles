{ config, pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      desktopManager.xfce.enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };
    displayManager.defaultSession = "xfce";
  };
}
