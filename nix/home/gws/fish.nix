{ pkgs, ... }:
{
  # Keep initialization in the shared fish config, not in HM-generated conf.d.
  home.packages = with pkgs; [
    fish
    starship
    zoxide
  ];

  xdg.configFile = {
    fish = {
      source = ../../../configs/fish/.config/fish;
      recursive = true;
    };
    "starship.toml".source = ../../../configs/starship/.config/starship.toml;
  };
}
