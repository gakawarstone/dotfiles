install:
	sudo cp configuration.nix /etc/nixos/configuration.nix
	sudo mkdir -p /etc/nixos/modules/desktop
	sudo mkdir -p /etc/nixos/modules/dev
	sudo cp modules/*.nix /etc/nixos/modules/
	sudo cp modules/desktop/*.nix /etc/nixos/modules/desktop/
	sudo cp modules/dev/*.nix /etc/nixos/modules/dev/
	sudo cp flake.nix /etc/nixos/
	if [ -f flake.lock ]; then sudo cp flake.lock /etc/nixos/; fi
	sudo nixos-rebuild switch --flake /etc/nixos/#gwsnix
	sudo cp /etc/nixos/flake.lock .
