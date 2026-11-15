{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Existing PC bindings call `lock`; the shared configuration calls swaylock
  # directly once the desktop configuration is migrated.
  home.file.".local/bin/lock" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec swaylock --daemonize --color 1e1e2e
    '';
  };
  home.activation.checkLockOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-lock-target.sh} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/lock"}
  '';
}
