JINJA_ENV ?= main

build:
	uvx --from jinjanator j2 ./alacritty.j2.toml ${JINJA_ENV}.env -o alacritty.toml

all: build
