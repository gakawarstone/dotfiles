#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
device="${MOBILE_SCREEN_DEVICE:-ipad}"
case "$device" in ipad|iphone) ;; *) printf 'Unknown mobile screen: %s\n' "$device" >&2; exit 1 ;; esac
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/sunshine-$device"
sunshine_version=2026.914.233613-1
sunshine_sha256=17eb8c4d823a2693038f40aeeab56943ef0d5d6ace8ac90b3693905b0acbba87

case "${1:-}" in
    ""|--configure-only) ;;
    *) printf 'Usage: %s [--configure-only]\n' "$0" >&2; exit 1 ;;
esac
[[ $EUID -ne 0 ]] || { printf 'Run as your desktop user, without sudo.\n' >&2; exit 1; }

if [[ "${1:-}" != --configure-only ]]; then
    [[ $(uname -m) == x86_64 ]] || { printf 'This installer requires Arch x86_64.\n' >&2; exit 1; }
    sudo pacman -S --needed curl jq
    installed_version=$(pacman -Q sunshine 2>/dev/null | awk '{print $2}' || true)
    if [[ -z "$installed_version" ]] || (( $(vercmp "$installed_version" "$sunshine_version") < 0 )); then
        download_dir=$(mktemp -d)
        trap 'rm -rf -- "$download_dir"' EXIT
        package="$download_dir/sunshine-$sunshine_version-x86_64.pkg.tar.zst"
        curl --fail --location --retry 3 --output "$package" \
            "https://github.com/LizardByte/Sunshine/releases/download/v${sunshine_version%-1}/sunshine-$sunshine_version-x86_64.pkg.tar.zst"
        printf '%s  %s\n' "$sunshine_sha256" "$package" | sha256sum --check
        sudo pacman -U --needed "$package"
    fi
fi

mkdir -p "$HOME/.local/bin" "$config_dir/credentials"
chmod 700 "$config_dir" "$config_dir/credentials"
target="$HOME/.local/bin/$device-screen"
if [[ -e "$target" || -L "$target" ]]; then
    [[ $(readlink -f "$target") == "$repo_dir/bins/$device-screen" ]] || {
        printf 'Refusing to overwrite existing %s\n' "$target" >&2; exit 1;
    }
else
    ln -s "$repo_dir/bins/$device-screen" "$target"
fi

if [[ ! -e "$config_dir/sunshine.conf" ]]; then
    cp "$repo_dir/configs/sunshine-$device/sunshine.conf" "$config_dir/sunshine.conf"
    # Explicit paths keep pairing state and keys out of the default Sunshine
    # profile and out of this repository.
    {
        printf '\nfile_apps = %s/apps.json\n' "$config_dir"
        printf 'file_state = %s/sunshine_state.json\n' "$config_dir"
        printf 'log_path = %s/sunshine.log\n' "$config_dir"
        printf 'pkey = %s/credentials/cakey.pem\n' "$config_dir"
        printf 'cert = %s/credentials/cacert.pem\n' "$config_dir"
    } >> "$config_dir/sunshine.conf"
fi
if [[ ! -e "$config_dir/apps.json" ]]; then
    cp "$repo_dir/configs/sunshine-$device/apps.json" "$config_dir/apps.json"
fi
chmod 600 "$config_dir/sunshine.conf" "$config_dir/apps.json"

hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
[[ -r "$hypr_dir/$device.lua" ]] || {
    printf 'Expected the dotfiles Hyprland config at %s.\n' "$hypr_dir" >&2; exit 1;
}
printf 'Configured. Start with: %s on\n' "$target"
if [[ "${1:-}" != --configure-only ]]; then
    if [[ ! -r /dev/uinput || ! -w /dev/uinput ]]; then
        printf 'Sunshine needs access to /dev/uinput. Log out and back in after installation.\n'
    fi
    "$target" on
fi
