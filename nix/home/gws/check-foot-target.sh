#!/usr/bin/env bash
set -eu

target=$1
source=$2
if [ ! -d "$source" ] || [ ! -f "$source/theme.ini" ]; then
    echo "foot: theme link is missing in $source (create it with: ln -sfn mocha.ini '$source/theme.ini')" >&2
    exit 1
fi
if [ -L "$target" ]; then
    link=$(readlink "$target" || true)
    case "$link" in
        /nix/store/*-home-manager-files/.config/foot) ;;
        *) echo "foot: preserve $target before activation" >&2; exit 1 ;;
    esac
    exit 0
fi
if [ -e "$target" ] && [ ! -d "$target" ]; then
    echo "foot: preserve $target before activation" >&2
    exit 1
fi
for name in foot.ini theme.ini; do
    path="$target/$name"
    if [ -e "$path" ] || [ -L "$path" ]; then
        target_link=$(readlink "$path" || true)
        case "$target_link" in
            /nix/store/*-home-manager-files/.config/foot/"$name"|"$source/theme.ini") ;;
            *) echo "foot: preserve $path before activation" >&2; exit 1 ;;
        esac
    elif [ "$name" = theme.ini ] && [ -L "$target/foot.ini" ]; then
        echo "foot: theme.ini is missing next to a managed foot.ini" >&2
        exit 1
    fi
done
