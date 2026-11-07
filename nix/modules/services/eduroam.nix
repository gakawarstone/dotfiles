{ config, pkgs, ... }:

let
  connectionId = "4010325c-14b4-47eb-af63-9518522eaa62";
  profilePath = "/etc/NetworkManager/system-connections/eduroam-${connectionId}.nmconnection";
  certificateDir = "/etc/NetworkManager/eduroam-material/${connectionId}";
in
{
  imports = [ ../system/secrets.nix ];

  sops.secrets."eduroam-profile" = {
    sopsFile = ../../secrets/eduroam.nmconnection.cfg;
    format = "binary";
    mode = "0600";
    restartUnits = [ "eduroam-profile.service" ];
  };

  sops.secrets."eduroam-ca-cert" = {
    sopsFile = ../../secrets/eduroam-ca-cert.cfg;
    format = "binary";
    mode = "0600";
    restartUnits = [ "eduroam-profile.service" ];
  };

  systemd.services.eduroam-profile = {
    description = "Install the eduroam NetworkManager profile";
    wantedBy = [ "multi-user.target" ];
    requires = [ "NetworkManager.service" ];
    after = [ "NetworkManager.service" ];
    path = [
      pkgs.coreutils
      pkgs.networkmanager
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0755 ${certificateDir}
      install -m 0644 ${config.sops.secrets."eduroam-ca-cert".path} ${certificateDir}/ca-cert

      temporary=$(mktemp /etc/NetworkManager/system-connections/.eduroam.XXXXXXXX)
      trap 'rm -f "$temporary"' EXIT
      install -m 0600 ${config.sops.secrets."eduroam-profile".path} "$temporary"
      mv -f "$temporary" ${profilePath}
      nmcli connection load ${profilePath}
    '';
  };
}
