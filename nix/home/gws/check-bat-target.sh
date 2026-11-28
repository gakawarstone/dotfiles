#!/usr/bin/env bash
set -eu

bat_dir=$1
bat_config="$bat_dir/config"
if [ -L "$bat_dir" ]; then
    echo "bat: the config directory is a symlink; unfold it before activation" >&2
    exit 1
fi
if [ -e "$bat_config" ] || [ -L "$bat_config" ]; then
    target=$(readlink "$bat_config" || true)
    case "$target" in
        /nix/store/*-home-manager-files/.config/bat/config) ;;
        *) echo "bat: preserve the existing config and release it from Stow before activation" >&2; exit 1 ;;
    esac
fi
