{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "helium";
  version = "0.20.1.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-1LeJsl0KmuEsdmceRE6Khe3Pgo4EGcZ40YxB+xrDAw4=";
  };

  contents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 "${contents}/helium.desktop" \
      "$out/share/applications/helium.desktop"
    install -Dm444 "${contents}/helium.png" \
      "$out/share/icons/hicolor/512x512/apps/helium.png"
  '';

  meta = {
    description = "Private, fast, and user-friendly Chromium browser";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
