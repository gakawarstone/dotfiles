# GKdots

A modular and automated configuration management system for Linux (Arch-based), using Python, GNU Stow, and Jinja2 templates.

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/gakawarstone/gkdots.git ~/dotfiles
   cd ~/dotfiles
   ```
2. **Initialize dependencies:**
   This installs `python`, `stow`, and `wget` via `pacman`.
   ```bash
   make init
   ```
3. **Configure your setup:**
   Edit `gkdots/config.py` (it will be created from `gkdots/config.def.py` on first install) to include the bins and configs you want to install.

4. **Decrypt secrets (Optional):**
   > [!WARNING]
   > Secret decryption is in an early stage. The API is subject to change, and its reliability is not yet guaranteed.
   ```bash
   make decrypt_secrets
   ```
5. **Install:**
   This bootstraps the config if missing, links binaries to `~/.local/bin`, and stows configurations to `~`.
   ```bash
   make install
   ```

## 📂 Project Structure

- `configs/`: Dotfiles organized by application (e.g., `alacritty/`, `fish/`, `tmux/`). Managed via GNU Stow.
- `bins/`: Custom scripts and binaries that are symlinked to `~/.local/bin/`.
- `gkdots/`: The core Python logic for the installation process.
- `packages/`: Source code for custom builds like `dwm`, `st`, and `slstatus`.
- `wallpapers/`: A collection of curated wallpapers.
- `scripts/`: Utility shell scripts for system maintenance and font management.
- `secrets/`: GPG-encrypted files managed by `gkdots/secrets.py`.

## 🛠 Features

- **Automated Symlinking**: Uses Python to safely link custom scripts.
- **Stow Integration**: Cleanly manages application configs in the home directory.
- **Suckless Management**: Automated build and link process for `dwm` and related tools.
- **Secret Management**: Simple GPG-based decryption workflow for sensitive configurations.
- **Templating**: Initial support for Jinja2 templates in configurations (e.g., Alacritty).

## 📝 Maintenance

- **Adding a config**: Add the folder to `configs/` and update `INCLUDED_CONFIGS` in `gkdots/config.py`.
- **Adding a binary**: Add the script to `bins/` and update `INCLUDED_BINS` in `gkdots/config.py`.
- **Cleaning up**: Use `make clean` to remove fonts and decrypted secrets.

## ⚠️ Warning

This setup is primarily designed for **Arch Linux**. The `make init` command uses `pacman`. If you are on another distribution, ensure you have `stow`, `python`, and `make` installed manually.
