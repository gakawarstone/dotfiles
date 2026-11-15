{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = ../../../configs/sunshine-iphone;
  configDir = "${config.xdg.configHome}/sunshine-iphone";
  conf = pkgs.writeText "sunshine-iphone.conf" ''
    ${builtins.readFile (source + /sunshine.conf)}
    file_apps = ${configDir}/apps.json
    file_state = ${configDir}/sunshine_state.json
    log_path = ${configDir}/sunshine.log
    pkey = ${configDir}/credentials/cakey.pem
    cert = ${configDir}/credentials/cacert.pem
  '';
  apps = source + /apps.json;
  previous = "${config.home.homeDirectory}/.local/state/home-manager/gcroots/current-home/home-files/.local/share/sunshine-managed/iphone";
  command = mode: ''
    PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.diffutils
      ]
    }:$PATH \
      ${pkgs.bash}/bin/bash ${./sync-sunshine-iphone.sh} ${mode} \
      ${lib.escapeShellArg configDir} ${lib.escapeShellArg (toString conf)} \
      ${lib.escapeShellArg (toString apps)} ${lib.escapeShellArg previous} /usr/bin/systemctl
  '';
in
{
  # Keep these generated templates distinct from private pairing and log data.
  xdg.dataFile."sunshine-managed/iphone/sunshine.conf".source = conf;
  xdg.dataFile."sunshine-managed/iphone/apps.json".source = apps;

  home.activation.checkSunshineIphone = lib.hm.dag.entryBefore [ "checkLinkTargets" ] (
    command "check"
  );
  home.activation.checkSunshineIphoneTemplates = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.bash}/bin/bash ${./check-sunshine-iphone-templates.sh} ${lib.escapeShellArg "${config.xdg.dataHome}/sunshine-managed/iphone"}
  '';
  home.activation.syncSunshineIphone = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "''${DRY_RUN:-}" ]; then
      ${command "apply"}
    fi
  '';
}
