{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".local/bin/webcam".source = ../../../bins/webcam;
  home.activation.checkWebcamOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-webcam-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/webcam"}
  '';
}
