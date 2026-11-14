{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.monaspace
    font-awesome
    helvetica-255
  ];
}
