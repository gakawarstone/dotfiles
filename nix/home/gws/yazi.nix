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
  xdg.configFile = {
    "yazi/yazi.toml".source = (pkgs.formats.toml { }).generate "yazi.toml" laptopConfig;
  };
}
