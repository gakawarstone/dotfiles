# Foot Terminal Configuration

This configuration uses Jinja2 templating with `jinjanator`.

## Theme
Uses the **Catppuccin Mocha** theme, located in `mocha.ini`.

## Build
Run `make` to generate the `foot.ini` file.
The default environment is `main.env`.
To use `laptop.env`, run:
```bash
JINJA_ENV=laptop make
```

## Structure
- `foot.j2.ini`: The Jinja2 template for the main configuration.
- `mocha.ini`: The Catppuccin Mocha theme.
- `main.env`: Variables for the main setup (e.g., font size).
- `laptop.env`: Variables for the laptop setup.
- `Makefile`: Build script to generate `foot.ini`.

## Installation
Home Manager links this directory to `~/.config/foot`. Before activation, run
`make prepare-foot` from the dotfiles root to generate missing `foot.ini` and
the default `theme.ini` link. Set `JINJA_ENV=laptop` for the laptop profile.
Existing files and links are preserved.

## Debugging
To see startup logs and debug configuration issues, run `foot` with the `info` log level from another terminal:
```bash
foot -d info
```
This will print detailed logs to `stderr`, which is useful for identifying syntax errors or missing fonts in your `foot.ini`.
