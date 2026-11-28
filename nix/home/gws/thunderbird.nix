{ ... }:
{
  programs.thunderbird = {
    enable = true;
    policies.ExtensionSettings."{47f5c9df-1d03-5424-ae9e-0613b69a9d2f}" = {
      installation_mode = "normal_installed";
      install_url = "file://${../../../configs/thunderbird/.config/thunderbird/mocha-mauve.xpi}";
    };
  };
}
