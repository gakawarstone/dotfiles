{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".codex/AGENTS.md".source = ../../../configs/codex/.codex/AGENTS.md;

  home.activation.checkCodexInstructionsTarget = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-codex-instructions-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.codex"}
  '';
}
