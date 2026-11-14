{
  config,
  lib,
  pkgs,
  ...
}:
{
  # The installer checks the resolved paths; the iPhone script also locates
  # the iPad script next to itself. Keep both in the existing checkout.
  home.file = {
    ".local/bin/ipad-screen".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/bins/ipad-screen";
    ".local/bin/iphone-screen".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/bins/iphone-screen";
  };
  home.activation.checkMobileScreenOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-mobile-screen-targets.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin"} ${lib.escapeShellArg "${config.home.homeDirectory}/dotfiles/bins"}
  '';
}
