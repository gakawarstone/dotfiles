#!/usr/bin/env bash

set -euo pipefail

config_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ -f "$HOME/.zen/profiles.ini" ]]; then
    zen_root="$HOME/.zen"
elif [[ -f "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini" ]]; then
    zen_root="$HOME/.var/app/app.zen_browser.zen/.zen"
else
    echo "Could not find a Zen profiles.ini file" >&2
    exit 1
fi

profiles_ini="$zen_root/profiles.ini"
profile_path=$(
    awk -F= '
        /^\[Install[^]]*\]$/ { in_install = 1; next }
        /^\[/ { in_install = 0 }
        in_install && $1 == "Default" {
            print substr($0, index($0, "=") + 1)
            exit
        }
    ' "$profiles_ini"
)

if [[ -z "$profile_path" ]]; then
    profile_path=$(
        awk -F= '
            /^\[Profile[0-9]+\]$/ { in_profile = 1; path = ""; next }
            /^\[/ { in_profile = 0 }
            in_profile && $1 == "Path" {
                path = substr($0, index($0, "=") + 1)
            }
            in_profile && $1 == "Default" && $2 == "1" {
                print path
                exit
            }
        ' "$profiles_ini"
    )
fi

if [[ -z "$profile_path" ]]; then
    echo "Could not determine the default Zen profile" >&2
    exit 1
fi

profile_dir="$zen_root/$profile_path"
chrome_dir="$profile_dir/chrome"
mkdir -p "$chrome_dir"

link_config() {
    local source=$1
    local target=$2

    if [[ -L "$target" && $(readlink -f "$target") == "$source" ]]; then
        echo "$target is already linked"
        return
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        echo "Refusing to replace existing file: $target" >&2
        exit 1
    fi

    ln -s "$source" "$target"
    echo "Linked $target"
}

link_config "$config_dir/userChrome.css" "$chrome_dir/userChrome.css"
link_config "$config_dir/user.js" "$profile_dir/user.js"

echo "Restart Zen to apply the configuration"
