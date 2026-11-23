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

### Stage 2 continuation: client visual streaming integrated

- `WorldVisualStreamer` is now wired into the actual OnlineWorld scene. It updates on clients with a valid local player and toggles geometry visibility by distance, leaving collision, NPC simulation, navigation meshes, and server world intact.
- The new `tests/main_world_visual_streaming_smoke.gd` verifies distant-zone culling, destination restoration and preserved NavigationRegion3D navmesh. PASS.
- This is **visibility culling, not asynchronous PackedScene streaming or RAM release**. Visual scenes remain in memory. The stage 2 objective of true chunk streaming and connected navigation remains open; do not claim FPS/RAM gains until measured on Android.

### Stage 2 continuation: actual decorative instance streaming

- Added `LunexStreamedDecor` component in real OnlineWorld. Four native editable `roadside_marker.tscn` decorative instances are created on proximity and queue_free'd beyond a hysteresis distance. Physics roads and navmesh stay persistent. `tests/main_world_decor_stream_smoke.gd` PASS.
- This is **real visual instance load/unload** but PackedScene resources are preloaded and instantiated on the main thread, not asynchronous disk streaming. It currently covers four lightweight decorative road markers, not terrain/entire zone geometry. Memory and frame-time impact not measured.
- The world is still NOT seamless for live players: cross-zone navigation meshes and authoritative server zone transitions remain unfinished. Task 2 remains open.

### Stage 2 continuation: navigation corridor regions and connectivity diagnostic

- Added native Godot-editable NavigationRegion3D / NavigationMesh to each of four inter-zone road scenes, preserving collision and geometry.
- `tests/main_world_navbridge_smoke.gd` validates navigation path across each corridor and separately checks full path from first to last zone. Four local corridor checks PASS, **full five-zone path currently FAILS (full_world_path=false)**. This is an explicit outstanding integration blocker, not a seamless world.
- Existing zone navmeshes must be rebuilt/stitched safely with obstacles and world offsets before server-authoritative continuous navigation can be enabled. Avoid naive full-world walkable plane because it would let autopilot walk through geometry.

### Seam diagnosis (2026-11-23)

- Checked corridor NavigationMesh triangle winding and tested explicit seam NavigationLink3D candidates. Neither produced a connected full-world path; temporary seam links were removed rather than leaving unverified obstacle-bypassing shortcuts.
- Full-world path currently stops at x≈10.8 in the starting zone. This indicates the legacy baked region edges do not stitch to the new corridor navmesh despite overlapping road geometry. Next implementation must rebuild/stitch navigation surfaces at exact matching boundaries, verify complete path endpoints, and run a live player collision test. The failed condition is intentionally preserved in diagnostics.
- Triangle-winding experiment broke all four local corridor path checks; reverted to last verified mesh orientation. Retest: four corridor paths PASS, full-world path remains false. No unverified navigation workaround shipped.

### Navigation correction attempt: collision-guarded rejection

- A single global narrow navigation strip can make `NavigationServer3D.map_get_path` report a complete route, but physics checks reveal existing collision obstacles along that path at x≈4 and x≈39. Therefore a naive strip would break server-authoritative auto-walk and is not safe.
- A hand-shaped detour mesh avoided sampled obstacle points but did not produce a continuous full-world navigation path; removed this unverified prototype. Restored original safe scene and diagnostic: four local corridor paths PASS, full-world path FALSE.
- Added `tests/main_world_obstacle_guard.gd` asserting both collision obstructions exist, so future path changes must account for real obstacles rather than only checking endpoints. Next: actual obstacle-aware navmesh rebake of the whole integrated geometry, with both full path and collision-free route assertions.

### Stage 2: navigation rebuilt from scratch (2026-11-23)

- `tests/rebuild_world_navmesh.gd` now generates `game/world/rebuilt_world_navigation.tres` offline from real physics collision samples of the actual five-zone OnlineWorld. Grid step 1 m, 9 sample positions per cell, obstacle height range 0.25–1.1 m. The resulting 2,219 walkable cells are represented by editable native Godot NavigationMesh triangles in `RebuiltWorldNavigation`.
- Full path (start x=0 to final x=168) now resolves. `tests/main_world_rebuilt_path_smoke.gd` samples the actual NavigationServer3D route every 0.2 m and checks collision: `MAIN_WORLD_REBUILT_PATH=PASS connected=true collision_free=true`.
- Editor import and geometry, visual culling, decorative instance streaming, bridge navigation, obstacle guard and inventory smoke tests PASS. Original baked region resources and original zone scenes remain preserved; this is an additive navigation replacement, not a destructive rewrite.
- Limitations: only the 0.25–1.1 m collision band and sampled path are verified; full character-radius sweeps, all start/end pairs, authoritative server movement, Android profiling, and actual asynchronous terrain chunk streaming are not yet verified. Do not claim production-ready seamless traversal.

### Stage 3 incremental: server-owned logical boundary crossing

- Added pure `LunexWorldZoneResolver` with X-axis zone boundaries, adjacent-zone validation and starting gate quest check. Server now observes authoritative player world position and changes logical zone without teleporting or zeroing velocity, with a reliable `_zone_changed` notification to the owning client.
- `tests/main_world_zone_resolver_smoke.gd` PASS for boundaries, adjacency and progression; `tests/main_world_continuous_membership_smoke.gd` PASS for preserved position and velocity. Godot 4.7.2 headless editor import PASS.
- **Not yet production-ready:** existing quest route code and manual gate travel RPC still teleport; an unqualified player can physically cross a boundary while logical zone remains unchanged. Must implement physical boundary enforcement and continuous quest route traversal, verify real ENet session and mobile client before stage 3 completion. Keep production unchanged.

### Stage 3 continuation: remove gate/quest teleports

- Server `_request_travel` now sets a navigation destination in the adjacent zone instead of calling `enter_zone` and `_arrive` to teleport.
- Server `_advance_quest_routes` now sets actual objective coordinates, and logical zone updates remain tied to observed server-side position. Existing quest gate checks retained.
- Added a physical X boundary clamp for an unqualified attempt to leave the training zone (gate-watch progression). Source invariant test verifies no `enter_zone` / `_arrive` in the two travel methods; eight Godot smoke tests and headless editor import PASS.
- **Not production accepted:** a full ENet two-peer movement test, full character-radius sweep, cross-zone combat visibility and manual Android acceptance remain outstanding. No production deploy.

### Stage 3 real ENet locked-boundary test

- `tests/main_world_enet_server.gd` and `tests/main_world_enet_client.gd` run in separate Godot 4.7.2 headless processes on isolated UDP 29047 and isolated SQLite `user://world_enet_29047.sqlite`.
- Client sends real ENet movement RPCs; server observes authoritative character coordinates. Both processes PASS; server observed maximum x=21.048 (near the x=21 boundary) and zone remained 0 for a profile without completed gate-watch quest.
- This verifies one real locked-boundary multiplayer scenario, not unlocked zone crossing, full cross-zone quest auto-navigation, or Android runtime. Stage 3 remains open until those tests pass.

### Stage 3 real ENet unlocked crossing (2026-11-23)

- Added independent server/client scripts `tests/main_world_enet_unlocked_server.gd` and `tests/main_world_enet_unlocked_client.gd` on isolated UDP 29048 and SQLite. Test server seeds the completed `gate_watch` quest for the connected profile, then observes real client input, server-authoritative movement and transition to zone 1 at x=21.123.
- Both separate Godot processes EXIT 0: server `MAIN_WORLD_ENET_UNLOCKED_SERVER=PASS`, client `MAIN_WORLD_ENET_UNLOCKED_CLIENT=PASS received_authoritative_zone=1`.
- Together with previous locked-boundary ENet test, verifies gate quest condition and actual zone synchronization on both peers. Cross-zone quest auto-navigation, longer routes, Android acceptance and CI still outstanding.

### Stage 3 quest navigation correction and ENet multi-zone smoke

- Fixed `_request_quest_route`: when an objective/giver/NPC is in another zone, the navigation destination is now the actual objective position rather than the gate marker. Previously the server would disable auto-navigation at the gate before crossing the world boundary.
- Added `tests/main_world_quest_route_source_smoke.gd` (PASS), and independent ENet server/client integration scripts `tests/main_world_enet_quest_server.gd`, `tests/main_world_enet_quest_client.gd` (UDP 29049, isolated DB). Test server seeds gate-watch completion and assigns a server-owned quest navigation destination at x=84. Without manual steering the player traversed both zone boundaries and reached zone 2 at x=63.119; client received authoritative zone 2. Both processes EXIT 0.
- The ENet test validates multi-zone navigation using `set_quest_destination`, but not the complete chapter-quest request RPC or objective interaction/reward. Those, Android manual acceptance and CI remain pending.

### Stage 3 complete chapter quest ENet integration

- Added `tests/main_world_enet_chapter_server.gd` and `tests/main_world_enet_chapter_client.gd`, isolated UDP 29050 and SQLite. Test server seeds `gate_watch` completion and chapter prerequisite `courtyard_report`, then activates `scout_contact` using production `chapter_accept`.
- Real client calls `_request_quest_route.rpc_id(1, "scout_contact")`; server runs real navigation into zone 1; client calls `_request_npc.rpc_id(1, "scout")` near actual NPC; production server validates NPC proximity, records objective and completes chapter quest. Client receives completed chapter state. Both processes EXIT 0; server x=40.631 zone1.
- This verifies the complete RPC quest route, NPC objective and progression state for one cross-zone chapter. Other chapter objectives, combat and Android acceptance are stage 4/5 scope.

### Stage 4 content regression kickoff

- Initial content regression suite: chapter quests (817), enemy quests (819), boss (820), full chapter/boss (826), monsters (832), side-quest authority (842), inventory (844) all exit 0.
- Existing `stage840_content_story_multizone.gd` initially failed because it asserted the old teleport-per-gate behavior. Updated it to assert the seamless-world contract: full-world final giver destination, no player teleport/zone mutation, route stays active. Revised test PASS.
- Content verification remains ongoing: real multi-client visibility, boss interactions, and persistence across zone boundaries require integration testing before stage 4 completion.

### Stage 4 persistent progression after reconnect

- `tests/main_world_crosszone_persistence.gd` creates isolated SQLite profile, completes `gate_watch`, chapter quest `first_steps`, grants XP/gold, closes DB, opens a fresh `LunexProgressStore` instance and verifies all four values survived reopen. PASS.
- This confirms persistence of zone-unlock prerequisite and chapter rewards across DB reconnect; it does not prove zone position is persisted or full network reconnect behavior. Multiplayer visibility and full reconnect remain outstanding.
