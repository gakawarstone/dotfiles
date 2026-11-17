install:
	@if [ ! -f gkdots/config.py ]; then \
		echo "Creating gkdots/config.py from defaults..."; \
		cp gkdots/config.def.py gkdots/config.py; \
	fi
	python ./gkdots/install.py

.PHONY: prepare-foot
prepare-foot:
	PYTHONPATH=gkdots python -c 'from pathlib import Path; from prepare import prepare_foot; prepare_foot(Path("configs/foot"))'

.PHONY: fonts
fonts:
	sh ./scripts/build_fonts.sh

clean:
	rm -f fonts/*

init:
	sudo pacman -S --noconfirm python stow wget uv swaylock
