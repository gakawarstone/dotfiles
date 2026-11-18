{ lib, pkgs, ... }:
{
  environment.variables = {
    # Override NixOS's default editor, while allowing host-specific choices.
    EDITOR = lib.mkOverride 900 "vim";
    VISUAL = lib.mkOverride 900 "vim";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    gnumake
    ripgrep
    bat
    btop
  ];
}
