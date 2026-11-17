{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."gtk-3.0/gtk.css".source = ../../../configs/gtk3/.config/gtk-3.0/gtk.css;
  home.activation.checkGtk3Ownership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-gtk3-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/gtk-3.0"}
  '';
}
