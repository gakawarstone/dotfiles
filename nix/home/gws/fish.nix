{ pkgs, ... }:
{
  # Keep initialization in the shared fish config, not in HM-generated conf.d.
  home.packages = with pkgs; [
    fish
    starship
    zoxide
  ];

  xdg.configFile = {
    "fish/config.fish".source = ../../../configs/fish/.config/fish/config.fish;
    "fish/conf.d/uv.env.fish".source = ../../../configs/fish/.config/fish/conf.d/uv.env.fish;
    "fish/conf.d/rustup.fish".source = ../../../configs/fish/.config/fish/conf.d/rustup.fish;
    "fish/conf.d/wt.fish".source = ../../../configs/fish/.config/fish/conf.d/wt.fish;
    "fish/completions/tasks.fish".source = ../../../configs/fish/.config/fish/completions/tasks.fish;
    "fish/completions/wt.fish".source = ../../../configs/fish/.config/fish/completions/wt.fish;
    "starship.toml".source = ../../../configs/starship/.config/starship.toml;
  };
}
