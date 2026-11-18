#!/usr/bin/env bash
set -eu

dir=$1
device=$2
case "$device" in iphone|ipad) ;; *) echo "sunshine: invalid device" >&2; exit 2 ;; esac
for path in "$(dirname "$dir")" "$dir"; do
    if [ -L "$path" ]; then
        echo "sunshine-$device: preserve the linked template directory: $path" >&2
        exit 1
    fi
done
for name in sunshine.conf apps.json; do
    path="$dir/$name"
    if [ -e "$path" ] || [ -L "$path" ]; then
        target=$(readlink "$path" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.local/share/sunshine-managed/"$device"/"$name") ;;
            *) echo "sunshine-$device: preserve the existing template: $path" >&2; exit 1 ;;
        esac
    fi
done
