{ osConfig, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ osConfig.sops.secrets.ssh-oracle.path ];
  };
}
