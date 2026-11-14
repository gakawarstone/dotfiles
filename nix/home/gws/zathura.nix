{ pkgs, ... }:
{
  home.packages = [ pkgs.zathura ];
  xdg.configFile."zathura/zathurarc".source = ../../../configs/zathura/.config/zathura/zathurarc;
}
