{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./zathura.nix ];

  # Keep Home Manager from treating an identical Stow file as already managed.
  home.activation.checkZathuraOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-zathura-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/zathura"}
  '';
}
