#!/usr/bin/env bash
set -euo pipefail
MOBILE_SCREEN_DEVICE=iphone exec "$(dirname -- "${BASH_SOURCE[0]}")/install_ipad_screen.sh" "$@"
