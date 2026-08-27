install:
	@if [ ! -f gkdots/config.py ]; then \
		echo "Creating gkdots/config.py from defaults..."; \
		cp gkdots/config.def.py gkdots/config.py; \
	fi
	python ./gkdots/install.py

.PHONY: fonts
fonts:
	sh ./scripts/build_fonts.sh

clean:
	rm -f fonts/*

init:
	sudo pacman -S --noconfirm python stow wget
