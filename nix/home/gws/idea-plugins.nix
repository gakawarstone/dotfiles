{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.ideaPlugins;
  plugin =
    {
      name,
      url,
      hash,
      directory,
    }:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.unzip ];
        src = pkgs.fetchurl { inherit url hash; };
      }
      ''
        unzip -q "$src" -d unpacked
        mv "unpacked/${directory}" "$out"
      '';
  ideaVim = plugin {
    name = "ideavim-2.48.1";
    url = "https://plugins.jetbrains.com/files/164/1207489/IdeaVIM-2.48.1.zip";
    hash = "sha256-2n8P6FzPNRc258JWRg2eiFTMa1e2L4JNbRi158h5vDY=";
    directory = "IdeaVIM";
  };
  catppuccin = plugin {
    name = "catppuccin-jetbrains-3.6.2";
    url = "https://plugins.jetbrains.com/files/18682/1215235/Catppuccin_Theme-3.6.2.zip";
    hash = "sha256-wDP00X+zworiq+IWYmv3C0IuwdPpZS6nXf3qBwEDhiI=";
    directory = "Catppuccin Theme";
  };
  pluginDir = ".local/share/JetBrains/IdeaIC2026.2";
in
{
  options.dotfiles.ideaPlugins = {
    ideaVim = lib.mkEnableOption "IdeaVim for IntelliJ IDEA 2026.2 on Arch";
    catppuccin = lib.mkEnableOption "Catppuccin for IntelliJ IDEA 2026.2 on Arch";
  };

  config.home.file = lib.mkMerge [
    (lib.mkIf cfg.ideaVim { "${pluginDir}/IdeaVIM".source = ideaVim; })
    (lib.mkIf cfg.catppuccin { "${pluginDir}/Catppuccin Theme".source = catppuccin; })
  ];
}
