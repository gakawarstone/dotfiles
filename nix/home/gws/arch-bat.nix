{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./bat.nix ];

  # Identical Stow files can otherwise be skipped by Home Manager, leaving the
  # apparent owner unchanged and allowing a later activation to write through
  # a folded directory link into the original checkout.
  home.activation.checkBatOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-bat-target.sh} ${lib.escapeShellArg "${config.xdg.configHome}/bat"}
  '';
}
