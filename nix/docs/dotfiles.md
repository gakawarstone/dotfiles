# Laptop dotfiles

The laptop deliberately uses an editable checkout of this repository at
`~/dotfiles`. Nix pins the Neovim configuration through the `nvim` flake input;
Herdr and the scripts listed below use the working checkout directly. A Nix
rebuild does not fetch or update it.

`nix/home/gws/editor.nix` patches the pinned Neovim source to select the official
JetBrains Kotlin server installed by Nix. Running `make -C nix switch` from the
repository root includes the Kotlin migration without overriding the input to a
local checkout.
Remove `nix/home/gws/nvim-kotlin.patch` and the source override when the `nvim` input
is updated to a revision that includes the migration. Completion remains manual:
press `Ctrl-Space` in insert mode to show suggestions.

The Kotlin server runs on Java 25, while its Gradle importer defaults to a
Nix-provided Java 21 so it works with Gradle 8 projects and avoids incompatible
downloaded JDKs. An explicit `com.jetbrains.ls.imports.gradle.java.home` in
`IJ_JAVA_OPTIONS` can override the default for other projects.

For user `gws`, clone this repository before starting the desktop:

```sh
git clone git@github.com:gakawarstone/dotfiles.git ~/dotfiles
```

If SSH authentication has not been restored yet, use the HTTPS URL instead:

```sh
git clone https://github.com/gakawarstone/dotfiles.git ~/dotfiles
```

Required paths used directly by this configuration:

| Path under `~/dotfiles` | Consumer |
| --- | --- |
| `configs/herdr/.config/herdr` | Home Manager symlink for the Herdr configuration |
| `configs/hyprland/.config/hypr` | Home Manager symlink for the Hyprland configuration |
| `configs/foot/.config/foot` | Mutable theme link used by `toggle_theme` |
| `configs/quickshell/.config/quickshell` | Mutable theme link used by `toggle_theme` |

`nix/home/gws/dotfiles.nix` manages the Herdr and Hyprland links. Before activation,
inspect `~/.config/hypr` and preserve any existing configuration or Stow link;
Home Manager needs to take ownership of that path. The checkout must contain
the laptop profile before enabling this link. `nix/home/gws/desktop.nix` installs the
shell wrappers with their runtime dependencies. `screen`, `toggle_theme` and its
Okular helper use repository snapshots, so changes require a rebuild. Keep the
checkout available at this location for the mutable configurations and themes.

Other desktop configuration in this repository must be installed using the
root README's setup instructions. Home Manager also supports the shared agent skills described in
the [shared skills guide](shared-skills.md). The Nix configuration manages the
links and wrappers listed above. The VM does not depend on this checkout.

## Codex instructions handoff

Home Manager manages only `~/.codex/AGENTS.md` from the repository through the
Nix store on both hosts. Changes to the source take effect after applying a new
Home Manager generation. The Codex configuration, credentials, sessions, and
other files under `~/.codex` remain local.

Before the first activation on each machine:

1. Check whether `~/.codex` itself is a symlink and inspect the existing
   `~/.codex/AGENTS.md`. Preserve any existing file or link and its contents;
   do not replace the entire `.codex` directory.
2. Ensure no Stow-based installer still manages `~/.codex/AGENTS.md`. The
   repository no longer ships one; an old checkout may keep a retired local
   `gkdots/config.py` on disk — leave it unused. Do not run Stow for Codex
   against the same target after the handoff.
3. After preserving any existing target, make `~/.codex/AGENTS.md` available for
   Home Manager. If `.codex` is a directory symlink, unfold it carefully while
   preserving its contents and other links. Home Manager's pre-activation check
   refuses an occupied target or a symlinked `.codex` directory.
4. Apply the appropriate Home Manager configuration when ready, then verify that
   `~/.codex/AGENTS.md` points to the Home Manager generation and that the local
   `config.toml` and other Codex data are intact. Inspect the laptop separately;
   its existing files have not been checked here.

The old `~/.codex/instructions.md` or `agents` links, if present, are separate
paths. Inspect them before deciding what to do with them; this handoff does not
remove them.
