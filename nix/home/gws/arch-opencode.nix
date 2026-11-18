{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./opencode.nix ];

  # Refuse identical Stow files too: they would otherwise remain unmanaged.
  home.activation.checkOpenCodeOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-opencode-targets.sh} ${lib.escapeShellArg "${config.xdg.configHome}/opencode"}
  '';
}
