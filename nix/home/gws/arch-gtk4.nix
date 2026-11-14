{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = ../../../configs/gtk4/.config/gtk-4.0;
in
{
  xdg.configFile = {
    "gtk-4.0/gtk.css".source = source + /gtk.css;
    "gtk-4.0/gtk-dark.css".source = source + /gtk-dark.css;
  };
  home.activation.checkGtk4Ownership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-gtk4-targets.sh} ${lib.escapeShellArg "${config.xdg.configHome}/gtk-4.0"}
  '';
}
