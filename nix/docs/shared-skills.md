# Shared agent skills

The laptop's existing NixOS Home Manager configuration and the standalone
`gws@arch` Home Manager configuration install these tracked skills individually
under `~/.agents/skills`: `grilling`, `improve-codebase-architecture`,
`report-relay`, `to-tasks`, and `typst`. Other names, including locally installed
skills such as `wizard`, are outside this configuration. It does not manage
`~/.codex/skills`.

These five directories are snapshots in the Nix store. Edits to the checkout
require a rebuild and activation before agents see them; generations retain their
own snapshots. Git-backed flakes include only files known to Git. This is a
limited choice for shared skills, not a decision about other dotfiles. Herdr
continues to use its existing editable out-of-store link.

## Before the first activation on each machine

1. Inspect `~/.agents`, `~/.agents/skills`, and the five named targets, including
   symlinks and their destinations. Compare any existing skills with the tracked
   versions; preserve local changes elsewhere before moving anything. Never delete
   a local skill merely to make activation succeed.
2. Check the machine's actual `gkdots/config.py` and other installers. If they
   install `agents` or any of these targets, stop them managing those paths before
   handing the paths to Home Manager. The tracked default does not enable `agents`,
   but the local selection may differ. Do not run Stow's `-D` on the package after
   Home Manager takes ownership: it could remove or interfere with links.
3. Stow may have made `~/.agents` or `~/.agents/skills` a single symlink into a
   checkout. Unfold it manually into real directories while preserving every
   unrelated entry and destination. Move each conflicting named skill or link to a
   safe backup outside the five target paths after inspecting it. Home Manager
   requires these parent directories to be real directories and stops before
   changing Home Manager files if a named target already exists outside a Home
   Manager generation, even when NixOS has its automatic backup policy enabled.
   Links from an existing Home Manager generation are allowed, so inspect those
   too before switching configurations.

The checks do not make a later Stow invocation safe. Keep one installer responsible
for each of the five paths. The existing Stow workflow remains available for other
packages.

## Evaluate and build without activation

From the repository root:

```sh
nix flake check --no-build --no-update-lock-file
nix build --no-link --no-update-lock-file '.#homeConfigurations."gws@arch".activationPackage'
nix eval --raw --no-update-lock-file '.#nixosConfigurations.gklaptop.config.system.build.toplevel.drvPath'
bash nix/tests/shared-skill-targets.sh
```

`gws@arch` is intentionally minimal: it manages only the shared skills and uses
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
