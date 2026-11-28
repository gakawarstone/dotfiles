{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file = {
    ".local/bin/toggle_theme".source = ../../../bins/toggle_theme;
    ".local/bin/sync_okular_theme".source = ../../../scripts/sync_okular_theme.sh;
  };
  home.activation.checkToggleThemeOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-toggle-theme-target.sh} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/toggle_theme"} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/sync_okular_theme"}
  '';
}
