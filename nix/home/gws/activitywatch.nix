{ pkgs, ... }:
let
  hasHyprlandSession = pkgs.writeShellScript "awatcher-has-hyprland-session" ''
    test -n "''${WAYLAND_DISPLAY:-}" && test -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}"
  '';
in
{
  services.activitywatch = {
    enable = true;
    package = pkgs.aw-server-rust;
  };

  systemd.user.services.awatcher = {
    Unit = {
      Description = "Track active apps and idle time for ActivityWatch";
      # UWSM waits for WAYLAND_DISPLAY and HYPRLAND_INSTANCE_SIGNATURE before
      # reaching this target. Order after it so each login gets fresh values.
      After = [
        "graphical-session.target"
        "activitywatch.service"
      ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "activitywatch.service" ];
    };
    Service = {
      # Skip non-Hyprland sessions without failing and triggering Restart=.
      ExecCondition = "${hasHyprlandSession}";
      ExecStart = "${pkgs.awatcher}/bin/awatcher";
      Restart = "on-failure";
      RestartSec = 5;
    };
    # The server stays on HM's independent activitywatch.target; only the
    # watcher follows graphical logins and logouts.
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
