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
Home Manager renders `foot.ini` from `foot.j2.ini`; the font size is selected
per host in the Nix configuration (`dotfiles.foot.font-size`). It links
`~/.config/foot/theme.ini` to this directory, where `bins/toggle_theme` swaps
the theme. Before activating on a new machine, create the missing `theme.ini`
link with `make prepare-foot` from the dotfiles root. Existing theme links are
preserved.

## Debugging
To see startup logs and debug configuration issues, run `foot` with the `info` log level from another terminal:
```bash
foot -d info
```
This will print detailed logs to `stderr`, which is useful for identifying syntax errors or missing fonts in your `foot.ini`.
