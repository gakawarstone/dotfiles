{ config, ... }:
{
  # Mutable by design. See docs/dotfiles.md for the required checkout.
  xdg.configFile."herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/herdr/.config/herdr";
}
