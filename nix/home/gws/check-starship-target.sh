#!/usr/bin/env bash
set -eu

target_path=$1
if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    target=$(readlink "$target_path" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/starship.toml) ;;
        *) echo "starship: preserve the existing config and release it from Stow before activation" >&2; exit 1 ;;
    esac
fi
