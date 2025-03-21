clean:
	rm -rf build
	rm -rf bin

deps:
	sudo pacman -S --noconfirm libxft libxinerama \
		xorg-xinit xorg-server ttf-dejavu

.PHONY: all clean build
build:
	sh build.sh

all: clean deps build
