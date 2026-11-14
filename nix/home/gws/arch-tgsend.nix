{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".local/bin/tgsend".source = ../../../bins/tgsend;
  home.activation.checkTgsendOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-tgsend-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/tgsend"}
  '';
}
