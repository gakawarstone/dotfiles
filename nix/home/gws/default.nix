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
    ./shared-skills.nix
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
