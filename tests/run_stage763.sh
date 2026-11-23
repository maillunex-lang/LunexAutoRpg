#!/bin/sh
set -eu
project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/opt/lunex-autorpg/bin/godot}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
timeout 35s "$godot_bin" --headless --path "$project" --script tests/stage763_store.gd -- "$scratch/chapter.sqlite"
