{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./lazygit.nix ];

  # An identical Stow file must not be mistaken for a Home Manager-owned link.
  home.activation.checkLazygitOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-lazygit-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/lazygit"}
  '';
}
