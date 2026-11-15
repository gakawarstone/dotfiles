#!/usr/bin/env bash
set -eu

target=$1
source=$2
if [ ! -d "$source" ] || [ ! -f "$source/foot.ini" ] || [ ! -f "$source/theme.ini" ]; then
    echo "foot: generated configuration or theme is missing in $source" >&2
    exit 1
fi
if [ -e "$target" ] || [ -L "$target" ]; then
    link=$(readlink "$target" || true)
    case "$link" in
        /nix/store/*-home-manager-files/.config/foot) ;;
        *) echo "foot: preserve $target before activation" >&2; exit 1 ;;
    esac
fi
