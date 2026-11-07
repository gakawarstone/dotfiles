{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services = {
    blueman.enable = true;
    power-profiles-daemon.enable = true;
    upower.enable = true;
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Only package-level RAPL energy is exposed to wheel for the user sampler.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="powercap", KERNEL=="intel-rapl:*", ATTR{name}=="package-*", RUN+="${pkgs.coreutils}/bin/chgrp wheel /sys%p/energy_uj", RUN+="${pkgs.coreutils}/bin/chmod 0440 /sys%p/energy_uj"
  '';

  # Clear a persisted rfkill software block before BlueZ starts.
  systemd.services.bluetooth-unblock = {
    description = "Unblock Bluetooth radio";
    requiredBy = [ "bluetooth.service" ];
    before = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };
}
