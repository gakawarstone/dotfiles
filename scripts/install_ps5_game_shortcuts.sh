#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
package_dir="$repo_dir/configs/ps5-pro/.local/share"
data_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}
bin_dir=${PS5_GAME_BIN_DIR:-"$HOME/.local/bin"}
icon_dir="$data_dir/icons/hicolor/512x512/apps"

for command in curl magick; do
    command -v "$command" >/dev/null || { printf 'Missing dependency: %s\n' "$command" >&2; exit 1; }
done

games=(gta-vi fc-27 god-of-war-ragnarok astros-playroom)
declare -A cover_urls=(
    [gta-vi]='https://image.api.playstation.com/vulcan/ap/rnd/202606/1818/9f51f0ccdb65bd29c36a0907a738c2902a712f03e2fd6470.png'
    [fc-27]='https://image.api.playstation.com/vulcan/ap/rnd/202607/2321/c7c534e1e9b24ccf7ff11c429948f31494ccce402b452647.png'
    [god-of-war-ragnarok]='https://psnobj.prod.dl.playstation.net/psnobj/NPWR22392_00/e7fdc8c6-d6ee-4345-b174-3ccb46f617b0.png'
    [astros-playroom]='https://image.api.playstation.com/vulcan/ap/rnd/202502/1908/3d17c33239dab88c7e2f24af50140b3f6fa555e6030d5704.png'
)

download_dir=$(mktemp -d)
trap 'rm -r -- "$download_dir"' EXIT
for game in "${games[@]}"; do
    curl --fail --silent --show-error --location --retry 2 --max-time 30 \
        --output "$download_dir/cover" "${cover_urls[$game]}"
    magick "$download_dir/cover" -resize 512x512 "$download_dir/$game-ps5.png"
done

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

link_file "$repo_dir/bins/ps5-game" "$bin_dir/ps5-game"
for file in launch.py cloud.py LICENSE; do
    link_file "$package_dir/gta-vi-ps5/$file" "$data_dir/gta-vi-ps5/$file"
done

mkdir -p -- "$icon_dir"
for game in "${games[@]}"; do
    install -m 644 -- "$download_dir/$game-ps5.png" "$icon_dir/$game-ps5.png"
    link_file "$package_dir/applications/$game-ps5.desktop" "$data_dir/applications/$game-ps5.desktop"
done
link_file "$package_dir/applications/ps5-games.desktop" "$data_dir/applications/ps5-games.desktop"

if command -v update-desktop-database >/dev/null; then
    update-desktop-database "$data_dir/applications"
fi

printf 'Installed the PS5 Pro Games launcher and four game shortcuts with artwork.\n'
printf 'The desktop session needs %s on PATH. Launching requires uv, secret-tool, the paired gws profile and chiaki-ng-framegen.\n' "$bin_dir"
