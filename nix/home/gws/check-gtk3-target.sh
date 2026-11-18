#!/usr/bin/env bash
set -eu

dir=$1
if [ -L "$dir" ]; then
    echo "gtk3: preserve the existing linked directory before activation" >&2
    exit 1
fi
path="$dir/gtk.css"
if [ -e "$path" ] || [ -L "$path" ]; then
    target=$(readlink "$path" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/gtk-3.0/gtk.css) ;;
        *) echo "gtk3: preserve $path before activation" >&2; exit 1 ;;
    esac
fi
