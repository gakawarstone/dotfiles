{ ... }:
let
  sourceDir = ../../../configs/opencode/.config/opencode;
in
{
  xdg.configFile = {
    "opencode/opencode.json".source = sourceDir + /opencode.json;
    "opencode/plugins/herdr-agent.js".source = sourceDir + /plugins/herdr-agent.js;
    "opencode/plugins/herdr-pane-title.js".source = sourceDir + /plugins/herdr-pane-title.js;
  };
}
