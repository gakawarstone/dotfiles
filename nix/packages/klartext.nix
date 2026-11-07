{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "klartext";
  version = "0.1.0-unstable-2026-08-10";

  src = fetchFromGitHub {
    owner = "HadiCherkaoui";
    repo = "klartext";
    rev = "04c9ee520c3c33cbc933377ae57321c82e191319";
    hash = "sha256-Hqb18ldhHQlFRG2JwaYWHGHBBDWue0MfVM4+mbdaWPk=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  cargoBuildFlags = [
    "-p"
    "klartext-cli"
  ];

  cargoTestFlags = [
    "-p"
    "klartext-cli"
  ];

  meta = {
    description = "BMW F-series diagnostics over ENET/HSFZ";
    homepage = "https://github.com/HadiCherkaoui/klartext";
    license = lib.licenses.agpl3Plus;
    mainProgram = "klartext";
  };
}
