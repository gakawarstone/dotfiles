{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".local/bin/toggle_theme".source = ../../../bins/toggle_theme;
  home.activation.checkToggleThemeOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-toggle-theme-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/toggle_theme"}
  '';
}
