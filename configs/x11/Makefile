JINJA_ENV ?= main

build:
	uvx --from jinjanator j2 ./config.j2.xinitrc ${JINJA_ENV}.env -o .xinitrc
	shfmt -w .xinitrc

all: build
