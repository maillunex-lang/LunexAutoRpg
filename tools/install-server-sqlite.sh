#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -f "$scratch/addons.zip"; rmdir "$scratch"' EXIT
curl -fLsS --retry 2 'https://github.com/2shady4u/godot-sqlite/releases/download/v4.9/addons.zip' -o "$scratch/addons.zip"
printf '%s  %s\n' 95e91b72fe32984a84edaf6357a78753661f37a170cb362f5b948e0ede7c2cb0 "$scratch/addons.zip" | sha256sum -c
unzip -nq "$scratch/addons.zip" 'addons/godot-sqlite/gdsqlite.gdextension*' 'addons/godot-sqlite/bin/libgdsqlite.linux.template_*.x86_64.so' 'addons/godot-sqlite/LICENSE.md' -d "$root"
: > "$root/addons/godot-sqlite/.gdignore"
