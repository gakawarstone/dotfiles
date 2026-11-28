{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./secrets.nix
    ../../modules/services/pass.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  users.users.gws = {
    isNormalUser = true;
    description = "gws";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      nvimSource = inputs.nvim;
    };
    backupFileExtension = "hm-bak";
    sharedModules = [ inputs.nvim.homeManagerModules.default ];
    users.gws = import ./.;
  };

  # The laptop has Neovim through Home Manager; other hosts keep the Vim default.
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  systemd.tmpfiles.rules = [
    "d ${config.users.users.gws.home}/.config 0755 gws users -"
    "d ${config.users.users.gws.home}/Images 0755 gws users -"
  ];
}
