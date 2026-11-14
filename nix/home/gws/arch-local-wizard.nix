{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = "${config.home.homeDirectory}/dotfiles/configs/agents/.agents/skills/wizard";
in
{
  # Preserve the existing PC-only local skill; it is not part of shared skills.
  home.file.".agents/skills/wizard".source = config.lib.file.mkOutOfStoreSymlink source;
  home.activation.checkLocalWizardOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ ! -f ${lib.escapeShellArg "${source}/SKILL.md"} ]; then
      echo "wizard: local skill source is missing" >&2
      exit 1
    fi
    ${pkgs.bash}/bin/bash ${./check-shared-skill-targets.sh} wizard
  '';
}
