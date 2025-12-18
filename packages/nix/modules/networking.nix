{ config, pkgs, ... }:

{
  networking.hostName = "gwsnix";
  networking.networkmanager.enable = true;
}
