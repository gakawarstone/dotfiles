#!/usr/bin/env bash
set -eu

dir=$1
source=$2
if [ ! -f "$source" ]; then
    echo "herdr: writable config source is missing: $source" >&2
    exit 1
fi
if [ -L "$dir" ]; then
    echo "herdr: preserve the linked configuration directory before activation" >&2
    exit 1
fi
path="$dir/config.toml"
if [ -e "$path" ] || [ -L "$path" ]; then
    target=$(readlink "$path" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/herdr/config.toml) ;;
        *) echo "herdr: preserve $path before activation" >&2; exit 1 ;;
    esac
fi
