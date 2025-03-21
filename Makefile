# NOTE: deprecated
update_fonts:
	bash ./scripts/update_fonts.sh

install:
	python ./gkdots/install.py

.PHONY: fonts
fonts:
	sh ./scripts/build_fonts.sh

clean:
	rm fonts/*

init:
	sudo pacman -S python stow wget
