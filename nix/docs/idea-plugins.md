# IDEA plugins on Arch

`gws@arch` manages IdeaVim and Catppuccin as individual plugin directories for
the Arch package's `IdeaIC2026.2` configuration. Their Marketplace archives,
versions and hashes are pinned in `nix/home/gws/idea-plugins.nix`. The existing
Arch IDEA package is not replaced. The chosen UI theme and editor colors remain
editable IDEA settings; `~/.ideavimrc` is managed separately.

Update the versions and hashes in the Nix module rather than using IDEA's plugin
updater. Check plugin compatibility when upgrading IDEA. In particular, a new
IDE version may use a different JetBrains plugin directory, which must also be
updated in the module.

Before the first activation, close IDEA and inspect the existing `IdeaVIM` and
`Catppuccin Theme` directories under `~/.local/share/JetBrains/IdeaIC2026.2`.
Preserve them outside the plugin directory before Home Manager takes ownership.
Home Manager does not overwrite these directories automatically. The user's
existing copies from the initial migration are in
`~/.local/state/dotfiles-backups/idea-plugins-20261113-174345/` on the PC.

The currently active generation on the PC was deliberately applied in stages.
The complete `gws@arch` configuration also includes active shared skills, if any.
