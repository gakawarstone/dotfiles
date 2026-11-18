{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/workstation.nix
    ../../home/gws/nixos.nix
    ../../modules/services/eduroam.nix
    ../../modules/desktop/hyprland.nix
  ];

  networking.hostName = "gklaptop";
  networking.extraHosts = ''
    192.168.178.22 gkfeed.local
  '';

  virtualisation.docker.enable = true;
  users.users.gws.extraGroups = [ "docker" ];

  # Keep rebuilds from saturating the laptop's 8 logical CPUs.
  nix.settings = {
    max-jobs = 2;
    cores = 2;
  };

  # Keep this at the NixOS release used for the target's first installation.
  system.stateVersion = "26.05";
}
