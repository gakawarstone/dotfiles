clean:
	rm -rf build
	rm -rf bin

deps:
	sudo pacman -S --noconfirm libxft libxinerama python-pywal16

.PHONY: all clean build
build:
	sh build.sh

all: clean deps build
