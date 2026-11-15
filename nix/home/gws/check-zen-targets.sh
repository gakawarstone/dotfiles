#!/usr/bin/env bash
set -eu

home=$1
profile=$2
awk_bin=$3
zen="$home/.zen"
source="$home/dotfiles/configs/zen"
ini="$zen/profiles.ini"
if [ -L "$zen" ] || [ ! -f "$ini" ]; then
    echo "zen: profiles directory or profiles.ini is unavailable" >&2
    exit 1
fi
default=$(
    "$awk_bin" '
        /^\[Install[^]]*\]$/ { in_install = 1; next }
        /^\[/ { in_install = 0 }
        in_install && /^Default=/ { print substr($0, 9) }
    ' "$ini"
)
if [ "$default" != "$profile" ]; then
    echo "zen: default profile changed; inspect it before activation" >&2
    exit 1
fi
dir="$zen/$profile"
if [ -L "$dir" ] || [ ! -d "$dir" ] || [ -L "$dir/chrome" ]; then
    echo "zen: preserve the profile and chrome directories before activation" >&2
    exit 1
fi
for relative in user.js chrome/userChrome.css; do
    name=${relative##*/}
    if [ ! -f "$source/$name" ]; then
        echo "zen: configuration source is missing: $source/$name" >&2
        exit 1
    fi
    target="$dir/$relative"
    if [ -e "$target" ] || [ -L "$target" ]; then
        link=$(readlink "$target" || true)
        case "$link" in
            /nix/store/*-home-manager-files/".zen/$profile/$relative") ;;
            *) echo "zen: preserve $target before activation" >&2; exit 1 ;;
        esac
    fi
done
