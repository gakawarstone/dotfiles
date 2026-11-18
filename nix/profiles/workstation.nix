{ ... }:
{
  imports = [
    ./minimal.nix
    ../modules/system/fonts.nix
    ../modules/services/audio.nix
  ];

  nixpkgs.config.allowUnfree = true;
}
