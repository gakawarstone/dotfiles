{ ... }:
{
  imports = [
    ./bat.nix
    ./lazygit.nix
    ./packages.nix
    ./development.nix
    ./editor.nix
    ./ideavim.nix
    ./dotfiles.nix
    ./fish.nix
    ./energy-meter.nix
    ./git.nix
    ./ssh.nix
    ./desktop.nix
    ./activitywatch.nix
  ];

  home.stateVersion = "26.05";
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
