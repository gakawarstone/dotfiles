{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    fastfetch
    nur.repos.Ev357.helium
    telegram-desktop
    zed-editor
    gnumake
  ];
}
