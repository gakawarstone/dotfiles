{
  description = "NixOS configuration with Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, nur, ... }@inputs: {
    nixosConfigurations.gwsnix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        {
          nixpkgs.overlays = [
            (final: prev: {
              nur = import nur {
                nurpkgs = prev;
                pkgs = prev;
              };
            })
          ];
        }
      ];
    };
  };
}
