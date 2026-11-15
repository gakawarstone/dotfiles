#!/usr/bin/env bash
set -eu

config_dir=$1
config_file="$config_dir/zathurarc"
if [ -L "$config_dir" ]; then
    echo "zathura: the config directory is a symlink; unfold it before activation" >&2
    exit 1
fi
if [ -e "$config_file" ] || [ -L "$config_file" ]; then
    target=$(readlink "$config_file" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/zathura/zathurarc) ;;
        *) echo "zathura: preserve the existing config and release it from Stow before activation" >&2; exit 1 ;;
    esac
fi
