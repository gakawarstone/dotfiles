{
  lib,
  pkgs,
  ...
}:

{
  # Fonts for the PC come through Home Manager; applications themselves stay
  # managed by pacman. The set mirrors the NixOS system fonts module.
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.monaspace
    font-awesome
    helvetica-255
  ];
}
