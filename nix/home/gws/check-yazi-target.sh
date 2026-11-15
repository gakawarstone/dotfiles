#!/usr/bin/env bash
set -eu

config_dir=$1
config_file="$config_dir/yazi.toml"
if [ -L "$config_dir" ]; then
    echo "yazi: preserve the existing directory link before activation" >&2
    exit 1
fi
if [ -e "$config_file" ] || [ -L "$config_file" ]; then
    target=$(readlink "$config_file" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/yazi/yazi.toml) ;;
        *) echo "yazi: preserve the existing config before activation" >&2; exit 1 ;;
    esac
fi
