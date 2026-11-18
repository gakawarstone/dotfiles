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
  xdg.configFile."mimeapps.list".source = ../../../configs/xdg-arch/.config/mimeapps.list;
  home.activation.checkXdgLinksOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-xdg-links.sh} ${lib.escapeShellArg home}
    ${pkgs.bash}/bin/bash ${./check-mimeapps-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/mimeapps.list"}
  '';
}
