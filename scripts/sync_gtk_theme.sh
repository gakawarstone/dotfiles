#!/usr/bin/env bash
set -eu

mode=${2:-}
theme=${1:?expected mocha or latte}
case "$theme" in mocha|latte) ;; *) echo "Unknown GTK theme: $theme" >&2; exit 1 ;; esac
state=${XDG_STATE_HOME:-"$HOME/.local/state"}/dotfiles-gtk
palette=${XDG_DATA_HOME:-"$HOME/.local/share"}/dotfiles-gtk/$theme.css
if [ -L "$state" ] || { [ -e "$state" ] && [ ! -d "$state" ]; }; then
    echo "GTK theme: preserve $state before switching" >&2
    exit 1
fi
current=$state/current.css
if [ -e "$current" ] || [ -L "$current" ]; then
    link=$(readlink "$current" || true)
    case "$link" in
        "${XDG_DATA_HOME:-$HOME/.local/share}"/dotfiles-gtk/mocha.css|"${XDG_DATA_HOME:-$HOME/.local/share}"/dotfiles-gtk/latte.css) ;;
        *) echo "GTK theme: preserve $current before switching" >&2; exit 1 ;;
    esac
fi
[ "$mode" = "--check" ] && exit 0
mkdir -p "$state"
ln -sfn "$palette" "$current"
