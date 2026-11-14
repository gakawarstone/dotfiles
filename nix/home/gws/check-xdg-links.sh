#!/usr/bin/env bash
set -eu

home=$1
for relative in \
    .local/share/applications/chatgpt.desktop \
    .local/share/applications/foot-directory.desktop \
    .local/share/icons/hicolor/180x180/apps/chatgpt.png; do
    target="$home/$relative"
    source="$home/dotfiles/configs/xdg/$relative"
    if [ ! -f "$source" ]; then
        echo "xdg: source missing: $source" >&2
        exit 1
    fi
    if [ -L "$(dirname "$target")" ]; then
        echo "xdg: preserve the linked parent directory of $target" >&2
        exit 1
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        link=$(readlink "$target" || true)
        case "$link" in
            /nix/store/*-home-manager-files/"$relative") ;;
            *) echo "xdg: preserve $target before activation" >&2; exit 1 ;;
        esac
    fi
done
