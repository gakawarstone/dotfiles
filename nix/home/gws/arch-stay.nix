{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".local/bin/stay".source = ../../../bins/stay;
  home.activation.checkStayOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-stay-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/stay"}
  '';
}
