# GKdots

A personal configuration repository for NixOS and Arch-based Linux, managed with Home Manager.

## 🚀 Quick Start

On a **NixOS** host, add the host to `nix/hosts/` and activate it with `nixos-rebuild`.

On **Arch Linux** (standalone Home Manager):

1. **Clone the repository:**
   ```bash
   git clone https://github.com/gakawarstone/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```
2. **Install dependencies:**
   Ensure you have `base-devel` installed for `make` to work:
   ```bash
   sudo pacman -S --needed base-devel
   make init
   ```
3. **Activate Home Manager:**
   ```bash
   nix build --no-link --print-out-paths \
     '.#homeConfigurations."gws@arch".activationPackage'
   <store-path>/activate
   ```

   Configuration files are installed by Home Manager from `configs/` and
   `bins/`; paths that already exist must be either free or owned by Home
   Manager — activation stops and asks you to preserve such files. Foot
   renders `foot.ini` from `configs/foot/.config/foot/foot.j2.ini` with the
   font size selected per host in the Nix configuration; on a new machine
   create the default theme link before activation with
   `ln -sfn mocha.ini configs/foot/.config/foot/theme.ini`. The theme stays
   mutable and is switched by `toggle_theme`.

## 📂 Project Structure

- `flake.nix`, `nix/`: Nix configuration: hosts, Home Manager modules, packages, checks.
- `configs/`: Configuration files for applications, installed by Home Manager.
- `bins/`: Custom scripts, installed by Home Manager or symlinked to `~/.local/bin/`.
- `packages/`: Source code for custom builds like `dwm`, `st`, and `slstatus`.
- `wallpapers/`: A collection of curated wallpapers.
- `scripts/`: Utility shell scripts for system maintenance and additional installers.

## 📝 Maintenance

- **Adding a config**: Add the folder to `configs/` and a Home Manager module in `nix/home/gws/`.
- **Adding a binary**: Add the script to `bins/` and install it in a Home Manager module.
- **Garbage collection**: Use `scripts/clean.sh` (Nix garbage collection).

For the PS5 PRO launcher, local wake-up, and the patched Chiaki-ng Flatpak,
see [PS5 PRO setup](configs/ps5-pro/README.md).

## ⚠️ Warning

This setup is primarily designed for **Arch Linux** and **NixOS**. The `make init` command uses `pacman`. If you are on another distribution, install the listed tools manually.
