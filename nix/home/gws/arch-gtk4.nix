{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/dotfiles-gtk/current.css";
in
{
  xdg.configFile = {
    "gtk-4.0/gtk.css".source = source;
    "gtk-4.0/gtk-dark.css".source = source;
  };
  home.activation.checkGtk4Ownership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-gtk4-targets.sh} ${lib.escapeShellArg "${config.xdg.configHome}/gtk-4.0"}
  '';
}
