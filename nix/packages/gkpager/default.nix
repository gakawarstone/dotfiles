{
  lib,
  rustPlatform,
  fetchFromCodeberg,
}:

rustPlatform.buildRustPackage {
  pname = "gkpager";
  version = "0.1.0-unstable-2026-05-13";

  src = fetchFromCodeberg {
    domain = "codeberg.org";
    owner = "gakawarstone";
    repo = "gkpager";
    rev = "dc346ceedb6ba54c084a63feaddc169efeb49e30";
    hash = "sha256-gNCP64KX1IjGcTAYxwE91M98594BU0Ps8XT6cVSHlkI=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Git diff pager with syntax highlighting and sticky headers";
    homepage = "https://codeberg.org/gakawarstone/gkpager";
    license = lib.licenses.mit;
    mainProgram = "gkpager";
  };
}
