#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [[ "$1" != /* ]]; then
    echo "Usage: sudo $0 /absolute/path/to/policies.json" >&2
    exit 2
fi
source=$1
root=${THUNDERBIRD_POLICY_TEST_ROOT:-}
if [ -n "$root" ] && [[ "$root" != /* ]]; then
    echo "Test root must be an absolute path" >&2
    exit 2
fi
if [ -z "$root" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Run as root to install the system policy" >&2
    exit 1
fi
if [ ! -f "$source" ]; then
    echo "Policy source is missing: $source" >&2
    exit 1
fi
install_dir="$root/etc/thunderbird/policies"
target="$install_dir/policies.json"
distribution="$root/usr/lib/thunderbird/distribution/policies.json"
for dir in "$root/etc/thunderbird" "$install_dir"; do
    if [ -L "$dir" ] || { [ -e "$dir" ] && [ ! -d "$dir" ]; }; then
        echo "Refusing to use non-directory or linked policy directory: $dir" >&2
        exit 1
    fi
done
if [ -e "$distribution" ] || [ -L "$distribution" ]; then
    echo "A Thunderbird distribution policy already exists: $distribution" >&2
    exit 1
fi
if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "Thunderbird policy already linked"
        exit 0
    fi
    echo "Refusing to replace existing Thunderbird policy: $target" >&2
    exit 1
fi
mkdir -p "$install_dir"
ln -s "$source" "$target"
echo "Thunderbird policy linked: $target"
