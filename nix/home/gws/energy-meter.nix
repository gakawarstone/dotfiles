{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.omaenergy ];

  # The Quickshell window in ~/dotfiles calls this exact path.
  home.file.".local/bin/omaenergy".source = "${pkgs.omaenergy}/bin/omaenergy";

  home.activation.energyMeterDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -d -m 0700 \
      "${config.home.homeDirectory}/.local/share/omarchy-energy" \
      "${config.home.homeDirectory}/.config/omarchy-energy"
  '';

  systemd.user.services.omarchy-energy = {
    Unit = {
      Description = "Energy Meter sampler";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.omaenergy}/bin/omaenergy daemon";
      Restart = "always";
      RestartSec = 5;
      KillSignal = "SIGTERM";
      TimeoutStopSec = 15;
      Nice = 10;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        "%h/.local/share/omarchy-energy"
        "%h/.config/omarchy-energy"
      ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = "AF_UNIX";
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = "@system-service";
      UMask = "0077";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
