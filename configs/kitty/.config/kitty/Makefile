JINJA_ENV ?= main

build:
	uvx --from jinjanator j2 ./kitty.j2.conf ${JINJA_ENV}.env -o kitty.conf

all: build
