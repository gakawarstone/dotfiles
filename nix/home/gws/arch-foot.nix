{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = "${config.home.homeDirectory}/dotfiles/configs/foot/.config/foot";
in
{
  # Preserve the generated configuration and the mutable theme link.
  xdg.configFile.foot.source = config.lib.file.mkOutOfStoreSymlink source;
  home.activation.checkFootOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-foot-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/foot"} ${lib.escapeShellArg source}
  '';
}
