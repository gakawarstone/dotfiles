{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = "${config.home.homeDirectory}/dotfiles/configs/herdr/.config/herdr/config.toml";
in
{
  # Herdr can edit its config; keep the existing checkout as the writable source.
  xdg.configFile."herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink source;
  home.activation.checkHerdrOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-herdr-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/herdr"} ${lib.escapeShellArg source}
  '';
}
