{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./fish-settings.nix ];
  home.activation.checkFishOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-fish-targets.sh} ${lib.escapeShellArg "${config.xdg.configHome}/fish"}
  '';
}
