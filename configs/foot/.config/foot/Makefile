JINJA_ENV ?= main

build:
	uvx --from jinjanator j2 ./foot.j2.ini ${JINJA_ENV}.env -o foot.ini

all: build
