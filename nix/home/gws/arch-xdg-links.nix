{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  source = ../../../configs/xdg;
in
{
  home.file = {
    ".local/share/applications/chatgpt.desktop".source =
      source + /.local/share/applications/chatgpt.desktop;
    ".local/share/icons/hicolor/180x180/apps/chatgpt.png".source =
      source + /.local/share/icons/hicolor/180x180/apps/chatgpt.png;
    ".local/share/applications/foot-directory.desktop".source =
      source + /.local/share/applications/foot-directory.desktop;
  };
  home.activation.checkXdgLinksOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-xdg-links.sh} ${lib.escapeShellArg home}
  '';
}
