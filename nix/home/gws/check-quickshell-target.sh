#!/usr/bin/env bash
set -eu

target=$1
source=$2
if [ ! -d "$source" ] || [ ! -f "$source/shell.qml" ]; then
    echo "quickshell: local configuration source is missing: $source" >&2
    exit 1
fi
if [ -e "$target" ] || [ -L "$target" ]; then
    link=$(readlink "$target" || true)
    case "$link" in
        /nix/store/*-home-manager-files/.config/quickshell) ;;
        *) echo "quickshell: preserve $target before activation" >&2; exit 1 ;;
    esac
fi
