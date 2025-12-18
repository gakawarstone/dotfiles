{ config, pkgs, ... }:

{
  users.users.gws = {
    isNormalUser = true;
    description = "gws";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
}
