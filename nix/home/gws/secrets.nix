{ config, ... }:
let
  home = config.users.users.gws.home;
  userSecret = file: {
    sopsFile = ../../secrets + "/${file}";
    format = "binary";
    owner = "gws";
    group = "users";
    mode = "0600";
  };
in
{
  imports = [ ../../modules/system/secrets.nix ];

  sops.secrets = {
    ssh-oracle = userSecret "ssh-oracle.cfg";
    wakatime = userSecret "wakatime.cfg" // {
      path = "${home}/.wakatime.cfg";
    };
    tgsend = userSecret "tgsend.cfg" // {
      path = "${home}/.config/tgsend/.env";
    };
    git-default-identity = userSecret "git-default-identity.cfg" // {
      path = "${home}/.gitconfig";
    };
    hsflensburg-identity = userSecret "hsflensburg-identity.cfg";
    hsflensburg-gitlab = {
      sopsFile = ../../secrets/gitlab-hs-flensburg.json;
      format = "json";
      key = "";
      owner = "gws";
      group = "users";
      mode = "0600";
    };
  };
}
