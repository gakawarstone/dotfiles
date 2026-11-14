#!/usr/bin/env bash
set -eu

dir=$1
if [ -L "$dir" ]; then
    echo "gtk4: preserve the existing linked directory before activation" >&2
    exit 1
fi
for name in gtk.css gtk-dark.css; do
    path="$dir/$name"
    if [ -e "$path" ] || [ -L "$path" ]; then
        target=$(readlink "$path" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.config/gtk-4.0/"$name") ;;
            *) echo "gtk4: preserve $path before activation" >&2; exit 1 ;;
        esac
    fi
done
