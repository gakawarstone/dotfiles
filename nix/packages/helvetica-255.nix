{
  fetchzip,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "helvetica-255";
  version = "1.0";

  src = fetchzip {
    url = "https://font.download/dl/font/helvetica-255.zip";
    hash = "sha256-J5efRtnF9O8V7ARZf5pG8Kj70NIpLnYzSWty1JedF3k=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    install -d "$out/share/fonts/truetype"
    install -m 0444 -t "$out/share/fonts/truetype" -- *.otf *.ttf

    runHook postInstall
  '';

  meta = {
    description = "Helvetica 255 font family";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
