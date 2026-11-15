{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkDevice =
    device:
    let
      label = if device == "iphone" then "Iphone" else "Ipad";
      source = ../../../configs + "/sunshine-${device}";
      configDir = "${config.xdg.configHome}/sunshine-${device}";
      conf = pkgs.writeText "sunshine-${device}.conf" ''
        ${builtins.readFile (source + /sunshine.conf)}
        file_apps = ${configDir}/apps.json
        file_state = ${configDir}/sunshine_state.json
        log_path = ${configDir}/sunshine.log
        pkey = ${configDir}/credentials/cakey.pem
        cert = ${configDir}/credentials/cacert.pem
      '';
      apps = source + /apps.json;
      previous = "${config.home.homeDirectory}/.local/state/home-manager/gcroots/current-home/home-files/.local/share/sunshine-managed/${device}";
      command = mode: ''
        PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.diffutils
          ]
        }:$PATH \
          ${pkgs.bash}/bin/bash ${./sync-sunshine-config.sh} ${mode} ${device} \
          ${lib.escapeShellArg configDir} ${lib.escapeShellArg (toString conf)} \
          ${lib.escapeShellArg (toString apps)} ${lib.escapeShellArg previous} /usr/bin/systemctl
      '';
    in
    {
      # Keep generated templates distinct from private pairing and log data.
      xdg.dataFile."sunshine-managed/${device}/sunshine.conf".source = conf;
      xdg.dataFile."sunshine-managed/${device}/apps.json".source = apps;

      home.activation."checkSunshine${label}" = lib.hm.dag.entryBefore [ "checkLinkTargets" ] (
        command "check"
      );
      home.activation."checkSunshine${label}Templates" = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        ${pkgs.bash}/bin/bash ${./check-sunshine-templates.sh} ${lib.escapeShellArg "${config.xdg.dataHome}/sunshine-managed/${device}"} ${device}
      '';
      home.activation."syncSunshine${label}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -z "''${DRY_RUN:-}" ]; then
          ${command "apply"}
        fi
      '';
    };
in
{
  imports = map mkDevice [
    "iphone"
    "ipad"
  ];
}
