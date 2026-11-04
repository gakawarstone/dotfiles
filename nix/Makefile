.PHONY: check check-build fmt fmt-check build test switch switch-install-bootloader update clean verify-host

CONFIGURATION ?= gklaptop
HARDWARE_CONFIG := hosts/$(CONFIGURATION)/hardware-configuration.nix
BUILD_OPTIONS_gklaptop := --max-jobs 2 --cores 2
BUILD_OPTIONS := $(BUILD_OPTIONS_$(CONFIGURATION))

check: fmt-check
	nix flake check --no-build --no-update-lock-file

check-build:
	nix flake check --no-update-lock-file $(BUILD_OPTIONS)

fmt:
	nix fmt --no-update-lock-file

fmt-check:
	nix build --no-link --no-update-lock-file .#checks.x86_64-linux.formatting

verify-host:
	@test -f "$(HARDWARE_CONFIG)" || { \
		echo "Missing $(HARDWARE_CONFIG)"; \
		echo "Copy the generated hardware configuration from the NixOS target first."; \
		exit 1; \
	}
	@if rg -q '^# This is a fake placeholder hardware configuration' "$(HARDWARE_CONFIG)"; then \
		echo "Replace the placeholder in $(HARDWARE_CONFIG) before building or activating this host."; \
		exit 1; \
	fi

build: verify-host
	nix build --no-update-lock-file ".#nixosConfigurations.$(CONFIGURATION).config.system.build.toplevel" $(BUILD_OPTIONS)

test: verify-host
	sudo nixos-rebuild test --flake ".#$(CONFIGURATION)" $(BUILD_OPTIONS)

clean:
	sudo nix-collect-garbage --delete-old
	sudo nix store optimise

switch: verify-host
	sudo nixos-rebuild switch --flake ".#$(CONFIGURATION)" $(BUILD_OPTIONS)

switch-install-bootloader: verify-host
	sudo nixos-rebuild switch --install-bootloader --flake ".#$(CONFIGURATION)" $(BUILD_OPTIONS)

update:
	nix flake update
