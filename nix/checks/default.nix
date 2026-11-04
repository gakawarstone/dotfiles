{
  pkgs,
  source,
  packages,
  hosts,
}:
packages
// {
  # Force the complete derivations: checking their type alone can miss lazy
  # option conflicts in generated configuration files.
  host-evaluation = builtins.deepSeq (builtins.mapAttrs (
    _: host: host.config.system.build.toplevel.drvPath
  ) hosts) (pkgs.runCommand "host-evaluation" { } ''touch "$out"'');

  formatting =
    pkgs.runCommand "nix-formatting"
      {
        nativeBuildInputs = [
          pkgs.nixfmt
          pkgs.ripgrep
          pkgs.findutils
        ];
      }
      ''
        cd ${source}
        rg --files --hidden -g '*.nix' -g '!.git/**' -0 | xargs -0 -r nixfmt --check
        touch "$out"
      '';
}
