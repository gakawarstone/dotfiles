{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/minimal.nix
    ../../modules/desktop/gnome.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.gws = {
    isNormalUser = true;
    description = "gws";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  networking.hostName = "vm";

  # Keep this at the NixOS release used for the target's first installation.
  system.stateVersion = "26.05";
}
