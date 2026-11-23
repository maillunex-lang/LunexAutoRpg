#!/bin/sh
set -eu
project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/opt/lunex-autorpg/bin/godot}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
python3 - "$scratch/old.sqlite" <<'PY'
import sqlite3,sys
with sqlite3.connect(sys.argv[1]) as db:
 db.execute("CREATE TABLE profiles (id TEXT PRIMARY KEY, quest INTEGER NOT NULL DEFAULT 0, experience INTEGER NOT NULL DEFAULT 0, equipped TEXT NOT NULL DEFAULT '')")
 db.execute("INSERT INTO profiles VALUES ('old_a', 2, 77, 'training_ring')")
 db.execute("INSERT INTO profiles VALUES ('old_b', 0, 0, '')")
 db.execute("CREATE TABLE quest_progress (profile TEXT NOT NULL, quest_id TEXT NOT NULL, state INTEGER NOT NULL, item TEXT NOT NULL DEFAULT '', equipped TEXT NOT NULL DEFAULT '', PRIMARY KEY (profile, quest_id))")
 db.execute("INSERT INTO quest_progress VALUES ('old_a','training',2,'training_ring','training_ring')")
 db.execute("CREATE TABLE chapter_quests (profile TEXT NOT NULL, quest_id TEXT NOT NULL, state INTEGER NOT NULL DEFAULT 0, objective_count INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(profile, quest_id))")
 db.execute("INSERT INTO chapter_quests VALUES ('old_a','first_steps',2,1)")
PY
python3 -c "import sqlite3,sys;db=sqlite3.connect(sys.argv[1]);db.execute('CREATE TABLE profiles (id TEXT PRIMARY KEY, experience INTEGER NOT NULL DEFAULT 0)');db.close()" "$scratch/broken.sqlite"
timeout 45s "$godot_bin" --headless --path "$project" --script tests/stage771_classes.gd -- "$scratch/old.sqlite" "$scratch/new.sqlite" "$scratch/broken.sqlite"
