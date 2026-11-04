{
  description = "Personal NixOS hosts and packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Keep Java 24 available for projects that require it after its removal.
    nixpkgs-java24.url = "github:nixos/nixpkgs/nixos-25.05";
    sops-nix.url = "github:Mic92/sops-nix";
    nvim = {
      url = "github:gakawarstone/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };
      localPackages = {
        inherit (pkgs)
          chatgpt-linux
          codex-bin
          gkpager
          helium
          helvetica-255
          herdr
          klartext
          kotlin-lsp
          omaenergy
          stud-gk
          t3code
          tgsend
          ;
      };
      mkHost =
        host:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.hostPlatform = system;
              nixpkgs.overlays = [ self.overlays.default ];
            }
            (./hosts + "/${host}")
          ];
        };
    in
    {
      overlays.default = import ./overlays { inherit inputs; };
      packages.${system} = localPackages // {
        inherit (pkgs) nixos-rebuild;
      };
      formatter.${system} = pkgs.nixfmt-tree;
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          nixfmt
          nixfmt-tree
          ripgrep
          gnumake
          sops
          age
          ssh-to-age
          python314
        ];
      };
      checks.${system} = import ./checks {
        inherit pkgs;
        source = self;
        packages = localPackages;
        hosts = self.nixosConfigurations;
      };
      nixosConfigurations = {
        gklaptop = mkHost "gklaptop";
        vm = mkHost "vm";
      };
    };
}
