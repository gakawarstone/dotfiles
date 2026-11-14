#!/usr/bin/env bash
set -eu

for parent in "$HOME/.agents" "$HOME/.agents/skills"; do
  if [ -L "$parent" ] || { [ -e "$parent" ] && [ ! -d "$parent" ]; }; then
    printf 'Shared skills: %s must be a real directory, not a symlink or file.\n' "$parent" >&2
    exit 1
  fi
done

for name in "$@"; do
  target="$HOME/.agents/skills/$name"
  if [ -L "$target" ]; then
    link=$(readlink "$target")
    case "$link" in
      /nix/store/*-home-manager-files/.agents/skills/"$name") continue ;;
    esac
  elif [ ! -e "$target" ]; then
    continue
  fi
  printf 'Shared skills: %s already exists; inspect and preserve it before activation.\n' "$target" >&2
  exit 1
done
