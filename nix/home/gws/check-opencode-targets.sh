#!/usr/bin/env bash
set -eu

config_dir=$1
if [ -L "$config_dir" ] || [ -L "$config_dir/plugins" ]; then
    echo "opencode: unfold the Stow directory links before activation" >&2
    exit 1
fi
for relative in opencode.json plugins/herdr-agent.js plugins/herdr-pane-title.js plugins/wakatime.js; do
    file="$config_dir/$relative"
    if [ -e "$file" ] || [ -L "$file" ]; then
        target=$(readlink "$file" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.config/opencode/"$relative") ;;
            *) echo "opencode: preserve $file and release it from Stow before activation" >&2; exit 1 ;;
        esac
    fi
done
