#!/usr/bin/env bash
set -euo pipefail

mode=$1
device=$2
config_dir=$3
desired_conf=$4
desired_apps=$5
previous_dir=$6
systemctl=$7
case "$device" in iphone|ipad) ;; *) echo "sunshine: invalid device" >&2; exit 2 ;; esac
case "$mode" in check|apply) ;; *) echo "sunshine-$device: invalid mode" >&2; exit 2 ;; esac
if [ -L "$config_dir" ] || { [ -e "$config_dir" ] && [ ! -d "$config_dir" ]; }; then
    echo "sunshine-$device: configuration directory must be a real directory" >&2
    exit 1
fi
needs_update=false
for name in sunshine.conf apps.json; do
    target="$config_dir/$name"
    case "$name" in sunshine.conf) desired=$desired_conf ;; apps.json) desired=$desired_apps ;; esac
    if [ -L "$target" ] || { [ -e "$target" ] && [ ! -f "$target" ]; }; then
        echo "sunshine-$device: preserve non-regular target: $target" >&2
        exit 1
    fi
    if [ -f "$target" ] && cmp -s "$target" "$desired"; then
        continue
    fi
    if [ -e "$target" ] && { [ ! -f "$previous_dir/$name" ] || ! cmp -s "$target" "$previous_dir/$name"; }; then
        echo "sunshine-$device: local changes require review: $target" >&2
        exit 1
    fi
    needs_update=true
done
if [ "$needs_update" = true ]; then
    status=$("$systemctl" --user is-active "$device-screen.service" 2>/dev/null || true)
    case "$status" in inactive|failed) ;; *) echo "sunshine-$device: stop the service before changing its configuration" >&2; exit 1 ;; esac
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
