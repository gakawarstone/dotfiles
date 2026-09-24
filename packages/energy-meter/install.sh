#!/usr/bin/env bash
# Install the upstream sampler used by the Quickshell Energy Meter window.
set -euo pipefail

repo_url=https://github.com/kevzakaria/omarchy-energy-meter.git
commit=1f920b7d99c4c2d61fe125ba36d22307b2edcb20
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checkout=$(mktemp -d)
trap 'rm -rf "$checkout"' EXIT

git clone --quiet "$repo_url" "$checkout"
git -C "$checkout" checkout --quiet "$commit"
git -C "$checkout" apply --unidiff-zero "$script_dir/patches/nvidia.patch"
"$checkout/install.sh"
systemctl --user start omarchy-energy.service
