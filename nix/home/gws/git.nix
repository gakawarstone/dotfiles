{ osConfig, pkgs, ... }:
let
  host = "gitlab.hs-flensburg.de";
  credentialHelper = pkgs.writeShellScript "hsflensburg-git-credential" ''
    [ "''${1:-}" = get ] || exit 0

    protocol=
    host=
    while IFS='=' read -r key value; do
      case "$key" in
        protocol) protocol=$value ;;
        host) host=$value ;;
      esac
    done
    [ "$protocol" = https ] && [ "$host" = ${host} ] || exit 0

    ${pkgs.jq}/bin/jq -er '
      select((.username | type == "string" and length > 0 and (contains("\n") | not) and (contains("\r") | not)) and
             (.token | type == "string" and length > 0 and (contains("\n") | not) and (contains("\r") | not))) |
      "username=\(.username)\npassword=\(.token)"
    ' ${osConfig.sops.secrets.hsflensburg-gitlab.path}
  '';
in
{
  xdg.configFile."git/config".text = ''
    [credential "https://${host}"]
        helper =
        helper = ${credentialHelper}
  '';
}
