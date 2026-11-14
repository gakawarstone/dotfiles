# Shared agent skills

Tracked skills have two source directories:

- `configs/agents/.agents/skills/` contains active skills. Home Manager links
  each directory here individually into `~/.agents/skills` on the laptop and
  in the standalone `gws@arch` configuration.
- `configs/agents/.agents/skills-disabled/` contains inactive skills. Home
  Manager does not install them. `grilling`, `improve-codebase-architecture`,
  `report-relay`, `to-tasks`, and `typst` are currently here.

The active source directory currently contains no skills. To enable one, move
its directory from `skills-disabled/` to `skills/`, stage the move for the
Git-backed flake, inspect the target as described below, then rebuild and activate
Home Manager on the chosen machine. To disable it again, move it back and apply
the new generation. Home Manager removes its own old link on activation; it does
not remove an independently installed copy.

`unslop` remains a locally installed skill, outside this configuration. Neither
its existing files nor its `~/.codex/skills` link are managed here. Other local
skills, including `wizard`, are also outside this configuration. A copy already
installed by another mechanism can remain discoverable even when its repository
version is disabled. Inspect each machine separately and preserve local content
before changing those copies. This change does not disable them on a running system.

Active skills use Nix store snapshots. Checkout edits require a rebuild and
activation before agents see them; generations retain their own snapshots.
Git-backed flakes include only files known to Git. This choice applies to shared
skills, not other dotfiles. Herdr keeps its editable out-of-store link.

## Before enabling a shared skill

1. Inspect `~/.agents`, `~/.agents/skills`, and the target skill, including
   symlinks and their destinations. Compare any existing skill with the tracked
   version; preserve local changes elsewhere before moving anything. Never delete
   a local skill merely to make activation succeed.
2. Check the machine's actual `gkdots/config.py` and other installers. If they
   install `agents` or the target, stop them managing that path before handing it
   to Home Manager. The tracked default does not enable `agents`, but the local
   selection may differ. Do not run Stow's `-D` on the package after Home Manager
   takes ownership: it could remove or interfere with links.
3. Stow may have made `~/.agents` or `~/.agents/skills` a single symlink into a
   checkout. Unfold it manually into real directories while preserving every
   unrelated entry and destination. Move each conflicting target to a safe backup
   after inspecting it. When at least one shared skill is active, Home Manager
   requires the parent directories to be real and stops before changing Home
   Manager files if a named target exists outside a Home Manager generation,
   including when NixOS has its automatic backup policy enabled. Links from an
   existing Home Manager generation are allowed, so inspect those too.

The checks do not make a later Stow invocation safe. Keep one installer responsible
for each active target. The existing Stow workflow remains available for other
packages. With no active shared skills, the target check is skipped.

## Evaluate and build without activation

From the repository root:

```sh
nix flake check --no-build --no-update-lock-file
nix build --no-link --no-update-lock-file '.#homeConfigurations."gws@arch".activationPackage'
nix eval --raw --no-update-lock-file '.#nixosConfigurations.gklaptop.config.system.build.toplevel.drvPath'
bash nix/tests/shared-skill-targets.sh
```

Git-backed flakes include tracked files only. During migration, if new modules
are still untracked, use `path:.` instead of `.` in these flake references. The
bat configuration is a Nix store snapshot of `configs/bat/.config/bat/config`;
edits to that file take effect after applying a new Home Manager generation.

`gws@arch` is intentionally minimal: it manages active shared skills, the bat,
lazygit, zathura, OpenCode, Starship, Yazi, fish, GTK 4 and Herdr configurations, Okular color schemes, PS5 launcher links, and selected screen, webcam, theme, stay and tgsend scripts,
IdeaVim, and the IDEA plugins described in
[idea-plugins.md](idea-plugins.md). It uses
`/home/gws` and Home Manager state version `26.05`. It does not install the
laptop's apps, secrets, or desktop configuration. Before adopting it, inspect any
existing standalone Home Manager configuration and generation on the PC. If one
already exists, merge the shared module into that configuration and retain its
existing state version instead of replacing it with this minimal configuration;
switching to a minimal generation can remove other Home Manager-managed links.

After the checks and the manual migration above, the standalone command from the
repository root is:

```sh
nix run .#home-manager -- switch --flake '.#gws@arch'
```

That command activates changes. On the laptop, the shared module is included in
the existing `gklaptop` NixOS rebuild; follow the same target inspection before
activating it. A failed Home Manager check during a NixOS switch does not undo
other parts of that switch. Evaluation and building alone do not inspect or alter
either home.
