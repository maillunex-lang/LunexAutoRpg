# WORLD-SEAMLESS-001 A — isolated proof of concept

Approved 2026-11-23: five exterior zones on a single seamless world; towns may load separately; instances/dungeons separately. First isolated demonstration links starting area to Ash Grove, without loading screens or production changes.

Current game uses independent NavigationRegion3D zones, zone gates and CSG walled enclosures. A production conversion requires preserving authoritative ENet movement and quest triggers; do not replace current live world blindly.

Prototype acceptance: Godot 4.7.2 native editable .tscn chunks, chunk streamer with bounded loaded set, contiguous 3D ground and player crossing, no scene-change calls, auto-navigation across chunk boundary, headless smoke test, documented limitations. No third-party source code integrated. No production service/database changes. Desktop editability is mandatory.

## Implementation status: isolated proof of concept

- Entry scene: `res://demo/seamless/seamless_demo.tscn` (open it in Godot editor to run the prototype).
- Native editable scene chunks: `demo/seamless/chunks/start_meadow.tscn`, `ash_grove_edge.tscn`. Each contains an editable MeshInstance3D and StaticBody3D ground. Two adjacent 24-unit chunks meet at Z=-12 with no scene switch.
- `chunk_streamer.gd` loads/unloads PackedScene instances near the tracked player and caps the prototype to two chunks. Preload radius 1 keeps both adjacent chunks resident during crossing; radius 0 demonstrates unload/reload, but may pop at a boundary.
- `seamless_demo.gd` follows an editable PackedVector3Array waypoint route to the second zone. This is a simple demonstration of continuous auto-travel, NOT navmesh pathfinding or obstacle avoidance.
- Smoke: `res://tests/world_seamless_001_smoke.gd` checks same player instance, two-zone transition, waypoint arrival, chunk budget, unload/reload. Godot 4.7.2 headless PASS.
- Existing regression: stage831, stage832, stage844, stage845, stage848, stage849, stage850 PASS. Godot editor import PASS.

## Known gaps before production acceptance

1. Prototype is deliberately small and minimal, not the finished five-zone world. No landscape art pass, roads, vegetation, NPCs, buildings, mobs or world bosses have been migrated.
2. The isolated route is a straight-line waypoint demonstration, not NavigationServer3D pathfinding, and does not yet test moving around obstacles.
3. It is local-only: not integrated into ENet server-authoritative movement or multiplayer interest management; no real Android FPS/memory measurement.
4. Async loading, seamless background asset I/O, collision edge stress tests and five-zone streaming remain future milestones. No claims of zero hitching on a real device.
5. Cities may use loading screens under approved variant A; instances remain separate.
6. Production Godot server and SQLite were not touched. Manual demo acceptance required before any integration.
