{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."yazi/yazi.toml".source = ../../../configs/yazi/.config/yazi/yazi.toml;
  home.activation.checkYaziOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-yazi-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/yazi"}
  '';
}
