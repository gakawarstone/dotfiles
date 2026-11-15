#!/usr/bin/env bash
set -eu

dir=$1
if [ -L "$dir" ]; then
    echo "thunderbird: preserve the linked policy directory before activation" >&2
    exit 1
fi
path="$dir/policies.json"
if [ -e "$path" ] || [ -L "$path" ]; then
    target=$(readlink "$path" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.local/share/thunderbird-dotfiles/policies.json) ;;
        *) echo "thunderbird: preserve $path before activation" >&2; exit 1 ;;
    esac
fi
