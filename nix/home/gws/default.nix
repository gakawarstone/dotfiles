{ ... }:
{
  imports = [
    ./bat.nix
    ./lazygit.nix
    ./yazi.nix
    ./zathura.nix
    ./okular.nix
    ./thunderbird.nix
    ./opencode.nix
    ./packages.nix
    ./development.nix
    ./editor.nix
    ./ideavim.nix
    ./dotfiles.nix
    ./fish.nix
    ./gtk3.nix
    ./arch-gtk4.nix
    ./starship.nix
    ./stay.nix
    ./shared-skills.nix
    ./codex.nix
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
