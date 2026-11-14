{
  config,
  lib,
  nvimSource,
  pkgs,
  ...
}:
{
  programs.gakawarstone-nvim = {
    enable = true;
    extraPackages = with pkgs; [
      elmPackages.elm
      elmPackages.elm-format
      elmPackages.elm-language-server
      gopls
      kotlin-lsp
      ktlint
      lua-language-server
      marksman
      nil
      nixfmt
      prettier
      pyright
      ruff
      rust-analyzer
      stylua
      tailwindcss-language-server
      typescript-language-server
    ];
  };

  # Keep the pinned config in sync with the official server installed above.
  # Remove this patch once the nvim input includes the Kotlin migration.
  xdg.configFile."nvim".source = lib.mkForce (
    pkgs.applyPatches {
      name = "nvim-config";
      src = nvimSource;
      patches = [ ./nvim-kotlin.patch ];
    }
  );

  home.file.".local/bin/nvim".source = pkgs.writeShellScript "gakawarstone-nvim" ''
    export PATH="${config.home.path}/bin:$PATH"
    exec "${config.home.path}/bin/nvim" "$@"
  '';
}
