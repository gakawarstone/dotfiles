{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  source = "${home}/dotfiles/configs/xdg";
  files = [
    ".local/share/applications/chatgpt.desktop"
    ".local/share/applications/foot-directory.desktop"
    ".local/share/icons/hicolor/180x180/apps/chatgpt.png"
  ];
in
{
  home.file = lib.genAttrs files (path: {
    source = config.lib.file.mkOutOfStoreSymlink "${source}/${path}";
  });
  home.activation.checkXdgLinksOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-xdg-links.sh} ${lib.escapeShellArg home}
  '';
}
