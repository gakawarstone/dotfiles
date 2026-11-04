{ pkgs, ... }:
let
  lock = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = [ pkgs.swaylock ];
    text = ''
      swaylock --daemonize --color 1e1e2e
    '';
  };
  screen = pkgs.writeShellApplication {
    name = "screen";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      grim
      slurp
      wl-clipboard
    ];
    text = ''
      exec ${pkgs.bash}/bin/bash "$HOME/dotfiles/bins/screen" "$@"
    '';
  };
  toggleTheme = pkgs.writeShellApplication {
    name = "toggle_theme";
    runtimeInputs = with pkgs; [
      coreutils
      glib
      procps
    ];
    text = ''
      exec ${pkgs.bash}/bin/bash "$HOME/dotfiles/bins/toggle_theme" "$@"
    '';
  };
in
{
  home.packages = [
    lock
    screen
    toggleTheme
  ];
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/xhtml+xml" = "helium.desktop";
      "text/html" = "helium.desktop";
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
    };
  };
}
