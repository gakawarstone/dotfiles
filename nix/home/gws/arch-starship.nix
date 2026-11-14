{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./starship.nix ];

  home.activation.checkStarshipOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-starship-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/starship.toml"}
  '';
}
