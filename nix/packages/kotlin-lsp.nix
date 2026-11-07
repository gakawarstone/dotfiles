{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  jdk21,
  jdk25,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = "263.7084.0";

  src = fetchurl {
    url = "https://download.jetbrains.com/language-server/kotlin-server/${finalAttrs.version}/kotlin-server-${finalAttrs.version}.tar.gz";
    hash = "sha256-rgxLAeF6tzpKUienjqmebcvj5JlgAxWyJ1mk5M3dEd8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  # Use the Nix-provided Java 25 runtime instead of the bundled Linux binaries.
  postPatch = ''
    rm -rf jbr
    ln -s ${jdk25.home} jbr
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/kotlin-lsp" "$out/bin"
    cp -a . "$out/lib/kotlin-lsp/"
    # Gradle 8 cannot run on the server's Java 25 runtime. Supply a compatible
    # Nix JDK instead of letting the importer pick an unpatched downloaded JDK.
    # Existing IJ_JAVA_OPTIONS follow this default and can override it.
    makeWrapper "$out/lib/kotlin-lsp/bin/intellij-server" "$out/bin/kotlin-lsp" \
      --prefix IJ_JAVA_OPTIONS " " "-Dcom.jetbrains.ls.imports.gradle.java.home=${jdk21.home}"
    ln -s kotlin-lsp "$out/bin/intellij-server"
    runHook postInstall
  '';

  meta = {
    description = "Official JetBrains Kotlin language server (Alpha)";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    license = lib.licenses.unfree;
    mainProgram = "kotlin-lsp";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      binaryBytecode
    ];
  };
})
