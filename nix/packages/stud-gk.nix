{
  appimageTools,
  fetchurl,
  lib,
  makeDesktopItem,
}:

let
  pname = "stud-gk";
  version = "1.0.0-build.17";

  src = fetchurl {
    url = "https://github.com/gakawarstone/stud.gk/releases/download/v${version}/Stud.GK-${version}-linux-x86_64.AppImage";
    hash = "sha256-zKejuzckzsrwhY/JSl0guUwl3r3XFTng0DmJMB7v9yo=";
  };

  contents = appimageTools.extractType2 {
    inherit pname version src;
  };

  desktopItem = makeDesktopItem {
    name = pname;
    # Upstream opens its own local UI and has no URL/file argument handler.
    exec = pname;
    desktopName = "Stud.GK";
    comment = "Local read-only Stud.IP companion";
    icon = pname;
    categories = [ "Education" ];
    startupWMClass = "Stud.GK";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 "${desktopItem}/share/applications/${pname}.desktop" \
      "$out/share/applications/${pname}.desktop"
    install -Dm444 "${contents}/usr/share/icons/hicolor/512x512/apps/${pname}.png" \
      "$out/share/icons/hicolor/512x512/apps/${pname}.png"
  '';

  meta = {
    description = "Local read-only Stud.IP companion";
    homepage = "https://github.com/gakawarstone/stud.gk";
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
