{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = "${config.home.homeDirectory}/dotfiles/configs/quickshell/.config/quickshell";
in
{
  # Keep local panel changes and the mutable theme in the existing checkout.
  xdg.configFile.quickshell.source = config.lib.file.mkOutOfStoreSymlink source;
  home.activation.checkQuickshellOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-quickshell-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/quickshell"} ${lib.escapeShellArg source}
  '';
}
