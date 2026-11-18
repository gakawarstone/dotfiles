{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  gcc,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  mesa,
  nspr,
  nss,
  pango,
  systemdLibs,
  tpm2-tss,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chatgpt-linux";
  version = "26.1023.51421";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${finalAttrs.version}_amd64.deb";
    hash = "sha256-RITcK1T8CXi+sjuNjXF0lOTgtPvqsKh2c5EF5QtE3lo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    gcc.cc.lib
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libnotify
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    mesa
    nspr
    nss
    pango
    systemdLibs
    tpm2-tss
  ];

  runtimeDependencies = [ systemdLibs ];

  # The bundle contains optional Qt integration shims and musl Node binaries.
  # OpenAI's Debian package does not depend on Qt or musl on glibc systems.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libc.musl-x86_64.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --extract
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -a usr/. "$out/"
    if [ -d opt ]; then
      mkdir -p "$out/opt"
      cp -a opt/. "$out/opt/"
    fi

    test -x "$out/bin/chatgpt"
    wrapProgram "$out/bin/chatgpt" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL ]}

    runHook postInstall
  '';

  meta = {
    description = "Official ChatGPT desktop app with Codex";
    homepage = "https://developers.openai.com/codex/linux/linux-app";
    license = lib.licenses.unfree;
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
