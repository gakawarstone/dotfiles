{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = "${config.home.homeDirectory}/dotfiles/configs/hyprland/.config/hypr";
in
{
  # Themes and host-specific local files are edited in the existing checkout.
  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink source;
  home.activation.checkHyprlandOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-hyprland-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/hypr"} ${lib.escapeShellArg source}
  '';
}
