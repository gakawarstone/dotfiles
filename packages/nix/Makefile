install:
	sudo cp configuration.nix /etc/nixos/configuration.nix
	sudo mkdir -p /etc/nixos/modules/desktop
	sudo cp modules/*.nix /etc/nixos/modules/
	sudo cp modules/desktop/*.nix /etc/nixos/modules/desktop/
	# Copy flake.nix and flake.lock (if it exists) to /etc/nixos/
	sudo cp flake.nix /etc/nixos/
	if [ -f flake.lock ]; then sudo cp flake.lock /etc/nixos/; fi
	# Run nixos-rebuild using the flake configuration
	sudo nixos-rebuild switch --flake /etc/nixos/#gwsnix
