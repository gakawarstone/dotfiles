#!/usr/bin/env bash
set -eu

dir=$1
source_dir=$2
if [ -L "$dir" ]; then
    echo "mobile-screen: preserve the linked bin directory before activation" >&2
    exit 1
fi
for name in ipad-screen iphone-screen; do
    if [ ! -x "$source_dir/$name" ]; then
        echo "mobile-screen: executable source missing: $source_dir/$name" >&2
        exit 1
    fi
    path="$dir/$name"
    if [ -e "$path" ] || [ -L "$path" ]; then
        target=$(readlink "$path" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.local/bin/"$name") ;;
            *) echo "mobile-screen: preserve $path before activation" >&2; exit 1 ;;
        esac
    fi
done
