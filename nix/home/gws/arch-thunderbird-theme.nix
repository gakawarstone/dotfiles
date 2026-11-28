{
  config,
  lib,
  pkgs,
  ...
}:
let
  theme = ../../../configs/thunderbird/.config/thunderbird/mocha-mauve.xpi;
in
{
  # This manages the policy data, not the Arch Thunderbird package or profiles.
  xdg.dataFile."thunderbird-dotfiles/policies.json".text = builtins.toJSON {
    policies.ExtensionSettings."{47f5c9df-1d03-5424-ae9e-0613b69a9d2f}" = {
      installation_mode = "normal_installed";
      install_url = "file://${theme}";
    };
  };
  home.activation.checkThunderbirdPolicyOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-thunderbird-policy-target.sh} ${lib.escapeShellArg "${config.xdg.dataHome}/thunderbird-dotfiles"}
  '';
}
