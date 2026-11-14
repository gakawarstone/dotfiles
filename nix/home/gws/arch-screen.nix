{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".local/bin/screen".source = ../../../bins/screen;
  home.activation.checkScreenOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-screen-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/screen"}
  '';
}
