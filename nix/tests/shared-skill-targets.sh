#!/usr/bin/env bash
set -eu

checker=$(cd "$(dirname "$0")/../home/gws" && pwd)/check-shared-skill-targets.sh
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"

pass() { bash "$checker" grilling typst; }
fail() {
  if pass 2>/dev/null; then
    printf 'Expected a collision to fail: %s\n' "$1" >&2
    exit 1
  fi
}

pass
mkdir -p "$HOME/.agents/skills/local-only"
pass
mkdir "$HOME/.agents/skills/typst"
fail 'existing skill directory'
rmdir "$HOME/.agents/skills/typst"
ln -s /missing "$HOME/.agents/skills/grilling"
fail 'dangling skill symlink'
rm "$HOME/.agents/skills/grilling"
ln -s /nix/store/example-home-manager-files/.agents/skills/grilling "$HOME/.agents/skills/grilling"
pass
rm "$HOME/.agents/skills/grilling"
rm -r "$HOME/.agents/skills"
ln -s /missing "$HOME/.agents/skills"
fail 'folded skills symlink'
rm "$HOME/.agents/skills"
rmdir "$HOME/.agents"
ln -s /missing "$HOME/.agents"
fail 'folded agents symlink'
printf 'Shared skill collision checks passed.\n'
