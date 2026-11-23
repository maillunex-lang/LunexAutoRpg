#!/bin/sh
set -eu
project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/opt/lunex-autorpg/bin/godot}
port=${1:-28761}
scratch=$(mktemp -d)
pid=
cleanup() {
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
    cat "$scratch/server.log" 2>/dev/null || true
    rm -rf "$scratch"
}
trap cleanup EXIT
"$godot_bin" --headless --path "$project" -- --server --port="$port" --database="$scratch/test.sqlite" >"$scratch/server.log" 2>&1 &
pid=$!
sleep 2
kill -0 "$pid"
timeout 35s "$godot_bin" --headless --path "$project" --script tests/stage76_smoke.gd -- 127.0.0.1 "$port"
if grep -E 'SCRIPT ERROR|^ERROR:' "$scratch/server.log"; then exit 1; fi
