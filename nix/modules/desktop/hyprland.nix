{
  config,
  lib,
  pkgs,
  ...
}:

let
  # The mutable dotfiles VPN helper runs these commands from Quickshell/Foot.
  vpnPath = lib.makeBinPath [
    pkgs.networkmanager
    pkgs.openconnect
    pkgs.python3
    pkgs.foot
  ];
  quickshellWithEffects = pkgs.symlinkJoin {
    name = "quickshell-with-effects";
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/quickshell" \
        --prefix PATH : "${vpnPath}" \
        --prefix QML_IMPORT_PATH : "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
      wrapProgram "$out/bin/qs" \
        --prefix PATH : "${vpnPath}" \
        --prefix QML_IMPORT_PATH : "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
    '';
  };
in
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  services = {
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        user = "greeter";
      };
    };

    gnome.gnome-keyring.enable = true;
  };

  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

    systemPackages = with pkgs; [
      brightnessctl
      kdePackages.dolphin
      dunst
      foot
      grim
      hyprpaper
      libnotify
      networkmanagerapplet
      playerctl
      quickshellWithEffects
      slurp
      swaylock
      wl-clipboard
      wofi
    ];
  };
}
