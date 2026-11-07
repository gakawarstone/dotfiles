{ pkgs, ... }:
let
  sourceDir = ../../../configs/yazi/.config/yazi;
  sourceConfig = builtins.fromTOML (builtins.readFile (sourceDir + /yazi.toml));
  laptopConfig = sourceConfig // {
    opener = builtins.removeAttrs sourceConfig.opener [ "portproton" ];
    open = sourceConfig.open // {
      rules = builtins.filter (rule: (rule.name or "") != "*.exe") sourceConfig.open.rules;
    };
  };
in
{
  home.packages = [
    pkgs.feh
    pkgs.gtk3
    pkgs.xdg-utils
  ];

  xdg.configFile = {
    "yazi/yazi.toml".source = (pkgs.formats.toml { }).generate "yazi.toml" laptopConfig;
    "yazi/init.lua".source = sourceDir + /init.lua;
    "yazi/plugins/git.yazi".source = pkgs.yaziPlugins.git;
  };
}
