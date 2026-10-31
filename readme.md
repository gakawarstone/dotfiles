# GKdots

A modular and automated configuration management system for Linux (Arch-based), using Python and GNU Stow.

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/gakawarstone/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```
2. **Initialize dependencies:**
   On Arch Linux, ensure you have `base-devel` installed for `make` to work:
   ```bash
   sudo pacman -S --needed base-devel
   ```
   Then install other dependencies via:
   ```bash
   make init
   ```
3. **Configure your setup:**
   Edit `gkdots/config.py` (it will be created from `gkdots/config.def.py` on first install) to include the bins and configs you want to install.
4. **Install:**
   This bootstraps the config if missing, links binaries to `~/.local/bin`, and stows configurations to `~`.
   ```bash
   make install
   ```

   When Alacritty or Foot is included, installation builds its missing config
   with `uvx` (from `uv`) using `main.env`. Set `JINJA_ENV=laptop` when
   running `make install` to use the laptop profile. Existing generated configs
   are left unchanged; rebuild them with `make` in the terminal's config
   directory to change profiles. Foot defaults to the Mocha theme if its
   `theme.ini` does not exist; an existing theme selection is preserved.
   Any `ConfigDirLinkingInfo` can also specify `prepare=...`, a function that
   receives the package directory as a `Path` and runs before Stow. See
   `gkdots/prepare.py` for examples.

## 📂 Project Structure

- `configs/`: Dotfiles organized by application (e.g., `alacritty/`, `fish/`, `tmux/`). Managed via GNU Stow.
- `bins/`: Custom scripts and binaries that are symlinked to `~/.local/bin/`.
- `gkdots/`: The core Python logic for the installation process.
- `packages/`: Source code for custom builds like `dwm`, `st`, and `slstatus`.
- `wallpapers/`: A collection of curated wallpapers.
- `scripts/`: Utility shell scripts for system maintenance and font management.

## 🛠 Features

- **Automated Symlinking**: Uses Python to safely link custom scripts.
- **Stow Integration**: Cleanly manages application configs in the home directory.
- **Suckless Management**: Automated build and link process for `dwm` and related tools.

## 📝 Maintenance

- **Adding a config**: Add the folder to `configs/` and update `INCLUDED_CONFIGS` in `gkdots/config.py`.
- **Adding a binary**: Add the script to `bins/` and update `INCLUDED_BINS` in `gkdots/config.py`.
- **Cleaning up**: Use `make clean` to remove downloaded fonts.

## ⚠️ Warning

This setup is primarily designed for **Arch Linux**. The `make init` command uses `pacman` and requires `base-devel` (for `make`). If you are on another distribution, ensure you have `stow`, `python`, and `make` installed manually.
