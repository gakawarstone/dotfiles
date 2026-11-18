# Fonts are installed by Home Manager (nix/home/gws/arch-fonts.nix).

.PHONY: init
init:
	sudo pacman -S --noconfirm curl flatpak python uv swaylock
