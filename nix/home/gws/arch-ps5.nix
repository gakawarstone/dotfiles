{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  checkout = "${home}/dotfiles";
  desktop = ".local/share/applications/io.github.streetpea.Chiaki4deck.desktop";
  icon = ".local/share/icons/hicolor/scalable/apps/ps5-pro.svg";
in
{
  # Keep the installer-compatible resolved paths, including the editable launcher.
  home.file = {
    ".local/bin/ps5-pro".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/bins/ps5-pro";
    "${desktop}".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/configs/ps5-pro/${desktop}";
    "${icon}".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/configs/ps5-pro/${icon}";
  };
  home.activation.checkPs5Ownership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-ps5-targets.sh} ${lib.escapeShellArg home}
  '';
}
