{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./okular.nix ];
  home.activation.checkOkularSchemesOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-okular-schemes.sh} ${lib.escapeShellArg "${config.xdg.dataHome}/color-schemes"}
  '';
}
