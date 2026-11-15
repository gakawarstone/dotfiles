#!/usr/bin/env bash
set -eu

dir=$1
if [ -L "$dir" ]; then
    echo "okular: preserve the existing color-schemes directory link before activation" >&2
    exit 1
fi
for name in CatppuccinLatteMauve.colors CatppuccinMochaMauve.colors; do
    path="$dir/$name"
    if [ -e "$path" ] || [ -L "$path" ]; then
        target=$(readlink "$path" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.local/share/color-schemes/"$name") ;;
            *) echo "okular: preserve $path before activation" >&2; exit 1 ;;
        esac
    fi
done
