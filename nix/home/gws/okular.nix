{ ... }:
let
  schemes = ../../../configs/okular/.local/share/color-schemes;
in
{
  xdg.dataFile = {
    "color-schemes/CatppuccinLatteMauve.colors".source = schemes + /CatppuccinLatteMauve.colors;
    "color-schemes/CatppuccinMochaMauve.colors".source = schemes + /CatppuccinMochaMauve.colors;
  };
}
