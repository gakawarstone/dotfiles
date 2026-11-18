#!/usr/bin/env bash
set -eu

codex_dir=$1
target="$codex_dir/AGENTS.md"
if [ -L "$codex_dir" ]; then
    echo 'codex: .codex is a symlink; preserve and unfold it before activation' >&2
    exit 1
fi
if [ -e "$target" ] || [ -L "$target" ]; then
    link=$(readlink "$target" || true)
    case "$link" in
        /nix/store/*-home-manager-files/.codex/AGENTS.md) ;;
        *) echo 'codex: preserve the existing AGENTS.md and release it before activation' >&2; exit 1 ;;
    esac
fi
