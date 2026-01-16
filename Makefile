# NOTE: deprecated
update_fonts:
	which unzip > /dev/null || sudo pacman -S --noconfirm unzip
	bash ./scripts/update_fonts.sh

install:
	@if [ ! -f gkdots/config.py ]; then \
		echo "Creating gkdots/config.py from defaults..."; \
		cp gkdots/config.def.py gkdots/config.py; \
	fi
	python ./gkdots/install.py

decrypt_secrets:
	python ./gkdots/secrets.py

.PHONY: fonts
fonts:
	sh ./scripts/build_fonts.sh

clean:
	rm -f fonts/*
	rm -rf .secrets

init:
	sudo pacman -S --noconfirm python stow wget
