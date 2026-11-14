#!/usr/bin/env bash
set -eu

dir=$1
for path in "$dir" "$dir/completions" "$dir/conf.d"; do
    if [ -L "$path" ]; then
        echo "fish: preserve the linked directory $path before activation" >&2
        exit 1
    fi
done
for relative in .gitignore config.fish completions/tasks.fish completions/wt.fish conf.d/rustup.fish conf.d/uv.env.fish conf.d/wt.fish; do
    path="$dir/$relative"
    if [ -e "$path" ] || [ -L "$path" ]; then
        target=$(readlink "$path" || true)
        case "$target" in
            /nix/store/*-home-manager-files/.config/fish/"$relative") ;;
            *) echo "fish: preserve $path before activation" >&2; exit 1 ;;
        esac
    fi
done
