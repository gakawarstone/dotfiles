#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
revision=c9fe2de1dc555d5e628665d6289f53f046a5426f
app_id=chiaki-ng-framegen
package_dir="$repo_dir/configs/ps5-pro-framegen/.local/share"
app_dir="$HOME/.local/opt/$app_id"
bin_dir="$HOME/.local/bin"
data_dir=${XDG_DATA_HOME:-$HOME/.local/share}
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/$app_id/Chiaki"
flatpak_config="$HOME/.var/app/io.github.streetpea.Chiaki4deck/config/Chiaki"

[[ $EUID -ne 0 ]] || { printf 'Run as your desktop user, without sudo.\n' >&2; exit 1; }
for cmd in git cmake ninja pkg-config c++; do
    command -v "$cmd" >/dev/null || { printf 'Missing dependency: %s\n' "$cmd" >&2; exit 1; }
done

work_dir=$(mktemp -d)
app_update=
trap 'rm -rf -- "$work_dir"; if [[ -n $app_update ]]; then rm -rf -- "$app_update"; fi' EXIT
src_dir="$work_dir/src"
build_dir="$work_dir/build"
stage_dir="$work_dir/install"

git init --quiet "$src_dir"
git -C "$src_dir" fetch --quiet --depth=1 https://github.com/chiaki-ng/chiaki-ng.git "$revision"
git -C "$src_dir" checkout --quiet --detach FETCH_HEAD
[[ $(git -C "$src_dir" rev-parse HEAD) == "$revision" ]]
git -C "$src_dir" submodule update --init --depth 1 --jobs 4 \
    third-party/nanopb third-party/jerasure third-party/gf-complete third-party/cpp-steam-tools

# Keep the app's Wayland identity separate while retaining Chiaki's settings format.
sed -i \
    -e 's/setDesktopFileName("chiaki-ng")/setDesktopFileName("chiaki-ng-framegen")/' \
    -e 's/setApplicationDisplayName("chiaki-ng")/setApplicationDisplayName("Chiaki-ng Frame Generation")/' \
    -e 's/QString("chiaki-ng:%1")/QString("Chiaki-ng Frame Generation (%1)")/' \
    "$src_dir/gui/src/main.cpp"

cmake -G Ninja -S "$src_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.10 \
    -DCHIAKI_ENABLE_TESTS=OFF -DCHIAKI_USE_SYSTEM_CURL=ON \
    '-DCMAKE_INSTALL_RPATH=$ORIGIN/lib'
cmake --build "$build_dir" --parallel "${CMAKE_BUILD_PARALLEL_LEVEL:-8}"
cmake --install "$build_dir" --prefix "$stage_dir"

# The desktop binary needs its private Steam Tools library after the build directory is removed.
install -d "$app_dir/lib" "$bin_dir" "$data_dir/applications" "$data_dir/icons/hicolor/512x512/apps"
app_update=$(mktemp -d "$app_dir/.install.XXXXXX")
install -m 755 "$stage_dir/bin/chiaki" "$app_update/chiaki"
install -m 755 "$stage_dir/lib/libcpp-steam-tools.so" "$app_update/libcpp-steam-tools.so"
mv -f -- "$app_update/libcpp-steam-tools.so" "$app_dir/lib/libcpp-steam-tools.so"
mv -f -- "$app_update/chiaki" "$app_dir/chiaki"

seed_profile() {
    awk '
        function settings() {
            print "[settings]"
            print "frame_generation=true"
            print "direct_frame_mapping=false"
            print "render_backend=vulkan"
            print "vulkan_startup_pending=false"
        }
        /^\[settings\]$/ { settings(); seeded = 1; next }
        /^(frame_generation|direct_frame_mapping|render_backend|vulkan_startup_pending|psn_auth_token|psn_refresh_token|psn_auth_token_expiry)=/ { next }
        { print }
        END { if (!seeded) settings() }
    ' "$1" > "$work_dir/profile.conf"
    install -m 600 "$work_dir/profile.conf" "$2"
}

# Seed local pairing on first install. Maintain a separate PSN login for each app.
if [[ ! -e "$config_dir/Chiaki.conf" ]]; then
    install -d -m 700 "$(dirname -- "$config_dir")" "$config_dir"
    for profile in "$flatpak_config"/Chiaki-*.conf; do
        [[ -f "$profile" && ! -e "$config_dir/${profile##*/}" ]] || continue
        seed_profile "$profile" "$config_dir/${profile##*/}"
    done
    if [[ -f "$flatpak_config/pl_render_params.conf" && ! -e "$config_dir/pl_render_params.conf" ]]; then
        install -m 600 "$flatpak_config/pl_render_params.conf" "$config_dir/pl_render_params.conf"
    fi
    profile="$flatpak_config/Chiaki.conf"
    [[ -f "$profile" ]] || profile=/dev/null
    seed_profile "$profile" "$config_dir/Chiaki.conf"
fi

install -m 755 "$repo_dir/bins/$app_id" "$bin_dir/$app_id"
install -m 644 "$package_dir/icons/hicolor/512x512/apps/ps5-pro-framegen.png" \
    "$data_dir/icons/hicolor/512x512/apps/ps5-pro-framegen.png"
install -m 644 "$package_dir/applications/$app_id.desktop" "$data_dir/applications/$app_id.desktop"
printf 'Installed PS5 PRO (Frame Generation).\n'
