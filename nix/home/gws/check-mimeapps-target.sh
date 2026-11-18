#!/usr/bin/env bash
set -eu

path=$1
if [ -L "$(dirname "$path")" ]; then
    echo "mimeapps: preserve the linked configuration directory before activation" >&2
    exit 1
fi
if [ -e "$path" ] || [ -L "$path" ]; then
    target=$(readlink "$path" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/mimeapps.list) ;;
        *) echo "mimeapps: preserve $path before activation" >&2; exit 1 ;;
    esac
fi
