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
| `bins/screen` | Personal `screen` screenshot wrapper |
| `bins/toggle_theme` | Personal `toggle_theme` wrapper |

`nix/home/gws/dotfiles.nix` manages the Herdr link. `nix/home/gws/desktop.nix` installs the
shell wrappers with their runtime dependencies. Changes to these dotfiles take
effect without rebuilding NixOS. Keep the checkout available at this location;
the Herdr link is otherwise dangling and the wrappers cannot run their scripts.

Other desktop configuration in this repository must be installed using the
root README's setup instructions. The Nix configuration manages only the links
and wrappers listed above. The VM does not depend on this checkout.
