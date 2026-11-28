{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.foot;
  checkout = "${config.home.homeDirectory}/dotfiles/configs/foot/.config/foot";
  source = ../../../configs/foot/.config/foot;
  template = builtins.readFile (source + /foot.j2.ini);
  palettes = builtins.readFile (source + /mocha.ini) + builtins.readFile (source + /latte.ini);
in
{
  options.dotfiles.foot.font-size = lib.mkOption {
    description = "Font size rendered into foot.ini from the shared template.";
    type = lib.types.strMatching "[0-9]+([.][0-9]+)?";
    default = "11";
  };

  config = {
    xdg.configFile = {
      # foot.ini is rebuilt from the template on every activation; the theme
      # stays mutable so bins/toggle_theme can swap it in the checkout.
      # Load both palettes before the theme link selects the initial theme.
      "foot/foot.ini".text =
        palettes + builtins.replaceStrings [ "{{font_size}}" ] [ cfg.font-size ] template;
      "foot/theme.ini".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/theme.ini";
    };

    home.activation.checkFootOwnership = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      ${pkgs.bash}/bin/bash ${./check-foot-target.sh} \
        ${lib.escapeShellArg "${config.xdg.configHome}/foot"} \
        ${lib.escapeShellArg checkout}
    '';
  };
}
