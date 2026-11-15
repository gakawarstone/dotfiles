#!/usr/bin/env bash
set -euo pipefail

mode=$1
config_dir=$2
desired_conf=$3
desired_apps=$4
previous_dir=$5
systemctl=$6
case "$mode" in check|apply) ;; *) echo "sunshine-iphone: invalid mode" >&2; exit 2 ;; esac
if [ -L "$config_dir" ] || { [ -e "$config_dir" ] && [ ! -d "$config_dir" ]; }; then
    echo "sunshine-iphone: configuration directory must be a real directory" >&2
    exit 1
fi
needs_update=false
for name in sunshine.conf apps.json; do
    target="$config_dir/$name"
    case "$name" in sunshine.conf) desired=$desired_conf ;; apps.json) desired=$desired_apps ;; esac
    if [ -L "$target" ] || { [ -e "$target" ] && [ ! -f "$target" ]; }; then
        echo "sunshine-iphone: preserve non-regular target: $target" >&2
        exit 1
    fi
    if [ -f "$target" ] && cmp -s "$target" "$desired"; then
        continue
    fi
    if [ -e "$target" ] && { [ ! -f "$previous_dir/$name" ] || ! cmp -s "$target" "$previous_dir/$name"; }; then
        echo "sunshine-iphone: local changes require review: $target" >&2
        exit 1
    fi
    needs_update=true
done
if [ "$needs_update" = true ]; then
    status=$("$systemctl" --user is-active iphone-screen.service 2>/dev/null || true)
    case "$status" in inactive|failed) ;; *) echo "sunshine-iphone: stop the service before changing its configuration" >&2; exit 1 ;; esac
fi
if [ "$mode" = check ] || [ "$needs_update" = false ]; then
    exit 0
fi
if [ ! -d "$config_dir" ]; then
    mkdir -p -m 700 "$config_dir"
fi
for name in sunshine.conf apps.json; do
    target="$config_dir/$name"
    case "$name" in sunshine.conf) desired=$desired_conf ;; apps.json) desired=$desired_apps ;; esac
    if [ -f "$target" ] && cmp -s "$target" "$desired"; then
        continue
    fi
    tmp=$(mktemp "$config_dir/.home-manager-$name.XXXXXX")
    trap 'rm -f -- "$tmp"' EXIT
    install -m 600 "$desired" "$tmp"
    mv -fT -- "$tmp" "$target"
    trap - EXIT
done
