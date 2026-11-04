{ lib, pkgs, ... }:
let
  names = [
    "grilling"
    "improve-codebase-architecture"
    "report-relay"
    "to-tasks"
    "typst"
  ];
  skills = ../../../configs/agents/.agents/skills;
in
{
  home.file = lib.genAttrs (map (name: ".agents/skills/${name}") names) (
    target:
    let
      name = baseNameOf target;
    in
    {
      source = skills + "/${name}";
    }
  );

  # Do not let Stow's folded directory links or HM's backup policy move local skills.
  home.activation.checkSharedSkillTargets = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-shared-skill-targets.sh} ${lib.escapeShellArgs names}
  '';
}
