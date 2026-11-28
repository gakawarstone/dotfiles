# Exposes the local derivations in ../packages as pkgs.<name>.
{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
  };
  java24Packages = import inputs.nixpkgs-java24 {
    system = final.stdenv.hostPlatform.system;
  };
in
{
  stud-gk = final.callPackage ../packages/stud-gk.nix { };
  chatgpt-linux = final.callPackage ../packages/chatgpt-linux.nix { };
  codex-bin = unstable.callPackage ../packages/codex-bin.nix { };
  elmPackages = prev.elmPackages.overrideScope (
    _: _: {
      elm = unstable.elmPackages.elm;
      elm-test = unstable.elmPackages.elm-test;
    }
  );
  opencode = unstable.opencode;
  jdk24 = java24Packages.temurin-bin-24;
  omaenergy = final.callPackage ../packages/omaenergy.nix { };
  gkpager = final.callPackage ../packages/gkpager { };
  helium = final.callPackage ../packages/helium.nix { };
  helvetica-255 = final.callPackage ../packages/helvetica-255.nix { };
  herdr = final.callPackage ../packages/herdr.nix { };
  klartext = final.callPackage ../packages/klartext.nix { };
  kotlin-lsp = final.callPackage ../packages/kotlin-lsp.nix { };
  t3code = final.callPackage ../packages/t3code.nix { };
  tgsend = final.callPackage ../packages/tgsend.nix { };
}
