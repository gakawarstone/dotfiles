{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openconnect ];
    dispatcherScripts = [
      {
        type = "pre-up";
        source = pkgs.writeShellScript "hsfl-vpn-mtu" ''
          if [ "''${2:-}" != "vpn-pre-up" ] ||
             [ "''${CONNECTION_ID:-}" != "HS Flensburg VPN" ] ||
             [ -z "''${VPN_IP_IFACE:-}" ]; then
            exit 0
          fi

          # The gateway negotiates MTU 1390 despite vpn.data.mtu=1280.
          # Enforce the working MTU before NetworkManager announces the VPN ready.
          exec ${pkgs.iproute2}/bin/ip link set dev "$VPN_IP_IFACE" mtu 1280
        '';
      }
    ];
  };

  environment.systemPackages = [ pkgs.openconnect ];

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.openssh.enable = true;
}
