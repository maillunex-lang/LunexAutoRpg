#!/bin/sh
# Run against an isolated server with Godot SQLite installed in this checkout.
set -eu

project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-godot}
port=${1:-28750}
scratch=$(mktemp -d)
probe=
cleanup() {
    if [ -n "$probe" ]; then
        kill "$probe" 2>/dev/null || true
        wait "$probe" 2>/dev/null || true
    fi
    if [ -f "$scratch/server.log" ]; then
        cat "$scratch/server.log"
    fi
    for file in progress.sqlite progress.sqlite-journal server.log; do
        if [ -f "$scratch/$file" ]; then unlink "$scratch/$file"; fi
    done
    rmdir "$scratch"
}
trap cleanup EXIT

export LUNEX_TEST_FIRST=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
export LUNEX_TEST_SECOND=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
python3 - "$scratch/progress.sqlite" <<'PY'
import hashlib
import os
import sqlite3
import sys

with sqlite3.connect(sys.argv[1]) as db:
    db.execute("CREATE TABLE profiles (id TEXT PRIMARY KEY, quest INTEGER NOT NULL DEFAULT 0, experience INTEGER NOT NULL DEFAULT 0, equipped TEXT NOT NULL DEFAULT '')")
    db.execute("CREATE TABLE quest_progress (profile TEXT NOT NULL, quest_id TEXT NOT NULL, state INTEGER NOT NULL, item TEXT NOT NULL DEFAULT '', equipped TEXT NOT NULL DEFAULT '', PRIMARY KEY (profile, quest_id))")
    for name in ("LUNEX_TEST_FIRST", "LUNEX_TEST_SECOND"):
        profile = hashlib.sha256(os.environ[name].encode()).hexdigest()
        db.execute("INSERT INTO profiles (id, experience) VALUES (?, 50)", (profile,))
        db.executemany(
            "INSERT INTO quest_progress VALUES (?, ?, 2, ?, ?)",
            [(profile, "training", "training_ring", "training_ring"),
             (profile, "gate_watch", "watch_medallion", "watch_medallion")],
        )
PY

start_server() {
    "$godot_bin" --headless --path "$project" -- --server --port="$port" --database="$scratch/progress.sqlite" >>"$scratch/server.log" 2>&1 &
    probe=$!
    sleep 1
    kill -0 "$probe"
}

start_server
timeout 55s "$godot_bin" --headless --path "$project" --script tests/stage75_smoke.gd -- 127.0.0.1 "$port"
kill "$probe"
wait "$probe" || true
probe=
start_server
timeout 15s "$godot_bin" --headless --path "$project" --script tests/stage75_smoke.gd -- 127.0.0.1 "$port" reload
if grep -E 'SCRIPT ERROR|^ERROR:' "$scratch/server.log"; then exit 1; fi
