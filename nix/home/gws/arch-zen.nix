{
  config,
  lib,
  pkgs,
  ...
}:
let
  profile = "vhkhxz28.Default (release)";
  source = "${config.home.homeDirectory}/dotfiles/configs/zen";
  target = ".zen/${profile}";
in
{
  # Keep the existing editable sources and the Zen installer's resolved paths.
  home.file = {
    "${target}/user.js".source = config.lib.file.mkOutOfStoreSymlink "${source}/user.js";
    "${target}/chrome/userChrome.css".source =
      config.lib.file.mkOutOfStoreSymlink "${source}/userChrome.css";
  };
  home.activation.checkZenOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-zen-targets.sh} \
      ${lib.escapeShellArg config.home.homeDirectory} ${lib.escapeShellArg profile} ${pkgs.gawk}/bin/awk
  '';
}
