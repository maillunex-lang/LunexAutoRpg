# LunexAutoRpg main-game seamless world integration

Owner direction 2026-11-23: implement actual original MMORPG, not standalone prototype. Era of Celestials is a gameplay reference, not a source of copyrighted assets, map, story or code.

## Verified current code architecture

- `game/network/online_world.tscn` already contains five region instances (`Navigation`, `Passage`, `AshGrove`, `SilentRuins`, `MistBell`) and separate teleport gates.
- `game/network/online_world.gd` uses `NavigationServer3D.map_get_path`, server-authoritative gate checks, `zone_id`, NPC zone filtering, and quest auto-routing through gates.
- `game/network/network_player.gd` stores authoritative zone and position and uses NavigationAgent3D.

## Production implementation sequence

1. Replace hard gate/teleport travel with continuous traversable corridors and a world-space sector map. Preserve authoritative movement and existing per-zone combat/quest isolation until server zone transitions are validated.
2. Author editable Godot `.tscn` terrain and chunk scene resources; streamed visuals must not remove authoritative collision/navmesh under an active player.
3. Convert quest auto-navigation to cross-zone routes; preserve current NPC/enemy quest state and anti-teleport checks.
4. Add streaming around each player on clients, while authoritative world simulation persists on server. Multiplayer interest management must not be coupled to client rendering.
5. Run 2-client ENet tests, persistence regression, Android low-memory profiling and manual visual acceptance. Then propose deployment with database backup and rollback.

## Current status

Stage 1 inspected and integration worktree created. No gameplay code or running production server changed. Existing isolated proof of concept remains reference-only; not merged blindly. Do not label full game as a completed clone.

## Stage 2 partial implementation (2026-11-23)

- Added four native Godot-editable `game/world/zone_corridor.tscn` road/collision segments into the **actual** `game/network/online_world.tscn`, between zone centers X=0/42/84/126/168.
- Added `game/world/world_visual_streamer.gd`, an opt-in visual-distance component which never unloads physics, navmesh or authoritative AI. Not yet wired to player visibility, pending safe network lifecycle handling.
- Godot 4.7.2 import and stage844 regression pass. **Do not consider the world seamless yet**: original CSG perimeter walls and disconnected navmeshes still block physical cross-zone traversal, and gate RPC still teleports players.
- No production deploy or database changes. Next task within stage 2: editor-editable openings, continuous navmesh and collision checks, then server-authoritative zone transition changes.

### Stage 2 continuation: traversable collision geometry

- Added native Godot editable `game/world/*_open.tscn` scene variants of all five existing zone geometries, preserving original assets unchanged. East/west perimeter walls removed only in integration variants, while north/south boundaries remain.
- Main `online_world.tscn` references these open scene variants and the four physical collision roads. Geometry smoke `tests/main_world_geometry_smoke.gd` PASS: all four corridor collisions and wall openings verified.
- Godot 4.7.2 editor import PASS and stage844 regression PASS.
- **Not yet seamless for actual player movement:** navmesh still disconnected and server still teleports via gate RPC. Visual streamer not wired into main game because visual hide and collision lifecycle require safe separation. Stage 2 remains IN PROGRESS.
