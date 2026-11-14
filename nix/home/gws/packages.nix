{ lib, pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      stud-gk
      fastfetch
      helium
      telegram-desktop
      zed-editor
      yazi
      gkpager
      klartext
      chatgpt-linux
      tgsend
    ]
    ++ lib.optionals (lib.hasAttr "legcord" pkgs) [ pkgs.legcord ];
}
