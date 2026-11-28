#!/usr/bin/env bash
set -eu

home=$1
for relative in \
    .local/bin/ps5-pro \
    .local/share/applications/io.github.streetpea.Chiaki4deck.desktop \
    .local/share/icons/hicolor/scalable/apps/ps5-pro.svg; do
    target="$home/$relative"
    case "$relative" in
        .local/bin/ps5-pro) source="$home/dotfiles/bins/ps5-pro" ;;
        *) source="$home/dotfiles/configs/ps5-pro/$relative" ;;
    esac
    if [ ! -f "$source" ]; then
        echo "ps5: source missing: $source" >&2
        exit 1
    fi
    if [ "$relative" = .local/bin/ps5-pro ] && [ ! -x "$source" ]; then
        echo "ps5: launcher is not executable: $source" >&2
        exit 1
    fi
    if [ -L "$(dirname "$target")" ]; then
        echo "ps5: preserve the linked parent directory of $target" >&2
        exit 1
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        link=$(readlink "$target" || true)
        case "$link" in
            /nix/store/*-home-manager-files/"$relative") ;;
            *) echo "ps5: preserve $target before activation" >&2; exit 1 ;;
        esac
    fi
done
