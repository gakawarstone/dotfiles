{
  fetchFromGitHub,
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "omaenergy";
  version = "1f920b7";

  src = fetchFromGitHub {
    owner = "kevzakaria";
    repo = "omarchy-energy-meter";
    rev = "1f920b7d99c4c2d61fe125ba36d22307b2edcb20";
    hash = "sha256-rBk73td2I2mhtNuKB8n+4xiFENLzhPswQ9ycRjweXc0=";
  };

  patches = [ ./omaenergy-nvidia.patch ];
  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ python3 ];
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    python3 ${./omaenergy-nvml-test.py} bin/omaenergy
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/omaenergy "$out/libexec/omaenergy"
    substituteInPlace "$out/libexec/omaenergy" \
      --replace-fail '#!/usr/bin/python3' '#!${python3}/bin/python3'
    makeWrapper "$out/libexec/omaenergy" "$out/bin/omaenergy" \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
    runHook postInstall
  '';

  meta = {
    description = "Energy Meter sampler and command-line interface";
    homepage = "https://github.com/kevzakaria/omarchy-energy-meter";
    license = lib.licenses.mit;
    mainProgram = "omaenergy";
    platforms = lib.platforms.linux;
  };
}
