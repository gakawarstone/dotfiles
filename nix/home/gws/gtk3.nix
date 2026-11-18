{
  config,
  lib,
  pkgs,
  ...
}:
let
  current = "${config.xdg.stateHome}/dotfiles-gtk/current.css";
in
{
  xdg.configFile."gtk-3.0/gtk.css".source = config.lib.file.mkOutOfStoreSymlink current;
  xdg.dataFile."dotfiles-gtk/mocha.css".source = ../../../configs/gtk3/.config/gtk-3.0/gtk.css;
  xdg.dataFile."dotfiles-gtk/latte.css".source = ../../../configs/gtk3/.config/gtk-3.0/latte.css;
  home.file.".local/bin/sync_gtk_theme".source = ../../../scripts/sync_gtk_theme.sh;
  home.activation.checkGtk3Ownership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-gtk3-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/gtk-3.0"}
    XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome} \
      ${pkgs.bash}/bin/bash ${../../../scripts/sync_gtk_theme.sh} mocha --check
  '';
  home.activation.initGtkTheme = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    if [ ! -e ${lib.escapeShellArg current} ] && [ ! -L ${lib.escapeShellArg current} ]; then
      theme=mocha
      case "$(readlink ${lib.escapeShellArg "${config.home.homeDirectory}/dotfiles/configs/hyprland/.config/hypr/theme.conf"} || true)" in
        *latte*) theme=latte ;;
      esac
      run env XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome} \
        ${pkgs.bash}/bin/bash ${../../../scripts/sync_gtk_theme.sh} "$theme"
    fi
  '';
}
