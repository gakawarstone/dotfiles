#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
release=weekly-canary-release-a9a2805884cfa83865fdfcc09ca3ddfcd628aa42
bundle_sha256=e26ec9b76837429015029f8d7f008e49dc3a3b69cacdae85b63cc7f01a9d7534

case "${1:-}" in
    ""|--configure-only) ;;
    *) printf 'Usage: %s [--configure-only]\n' "$0" >&2; exit 1 ;;
esac
[[ $EUID -ne 0 ]] || { printf 'Run as your desktop user, without sudo.\n' >&2; exit 1; }

if [[ "${1:-}" != --configure-only ]]; then
    [[ $(uname -m) == x86_64 ]] || { printf 'This installer requires x86_64.\n' >&2; exit 1; }
    for cmd in flatpak curl sha256sum python3; do
        command -v "$cmd" >/dev/null || { printf 'Missing dependency: %s\n' "$cmd" >&2; exit 1; }
    done
    download_dir=$(mktemp -d)
    trap 'rm -rf -- "$download_dir"' EXIT
    bundle="$download_dir/chiaki-ng-x64.flatpak"
    curl --fail --location --retry 3 --output "$bundle" \
        "https://github.com/chiaki-ng/chiaki-ng/releases/download/$release/chiaki-ng-x64.flatpak"
    printf '%s  %s\n' "$bundle_sha256" "$bundle" | sha256sum --check
    flatpak install --user --bundle --or-update --noninteractive -y "$bundle"
fi

backup_suffix="backup-$(date +%Y%m%d-%H%M%S)-$$"
link_file() {
    local source=$1 target=$2
    mkdir -p -- "$(dirname -- "$target")"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ $(readlink -f -- "$target") == "$source" ]]; then
            return
        fi
        mv -- "$target" "$target.$backup_suffix"
        printf 'Backed up %s\n' "$target"
    fi
    ln -s -- "$source" "$target"
}

link_file "$repo_dir/bins/ps5-pro" "$HOME/.local/bin/ps5-pro"
link_file "$repo_dir/configs/ps5-pro/.local/share/applications/io.github.streetpea.Chiaki4deck.desktop" \
    "$HOME/.local/share/applications/io.github.streetpea.Chiaki4deck.desktop"
link_file "$repo_dir/configs/ps5-pro/.local/share/icons/hicolor/scalable/apps/ps5-pro.svg" \
    "$HOME/.local/share/icons/hicolor/scalable/apps/ps5-pro.svg"

if command -v update-desktop-database >/dev/null; then
    update-desktop-database "$HOME/.local/share/applications"
fi
printf 'Installed PS5 PRO. Pair your console in Chiaki if this is a new machine.\n'
printf 'Check pairing and console status with: ps5-pro --check\n'
