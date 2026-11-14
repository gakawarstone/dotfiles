{ pkgs, ... }:
{
  imports = [ ./fish-settings.nix ];
  # Keep initialization in the shared fish config, not in HM-generated conf.d.
  home.packages = with pkgs; [
    fish
    starship
    zoxide
  ];

}
