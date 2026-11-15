{ lib, pkgs, ... }:
let
  # Only directories in skills/ are active; skills-disabled/ is never scanned.
  names = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skills)
  );
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
  home.activation.checkSharedSkillTargets = lib.mkIf (names != [ ]) (
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      ${pkgs.bash}/bin/bash ${./check-shared-skill-targets.sh} ${lib.escapeShellArgs names}
    ''
  );
}
