#!/usr/bin/env bash
set -eu

for path in "$@"; do
    name=${path##*/}
    case "$name" in toggle_theme|sync_okular_theme) ;; *) exit 2 ;; esac
    if [ -L "$(dirname "$path")" ]; then
        echo "toggle_theme: preserve the linked bin directory before activation" >&2
        exit 1
    fi
    if [ -e "$path" ] || [ -L "$path" ]; then
        target=$(readlink "$path" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.local/bin/"$name") ;;
            *) echo "toggle_theme: preserve $path before activation" >&2; exit 1 ;;
        esac
    fi
done
