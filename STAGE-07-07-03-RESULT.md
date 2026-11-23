# Stage 7.7.3 - Ability engine, awaiting acceptance

Owner accepted stage 7.7.2 and authorized 7.7.3 on 2026-11-23.

Implemented:
- Editable Godot ability definition Resource: ability ID, class, unlock level, cooldown, resource cost, range, target/effect type and status duration.
- Server-side executor: validates class, learned ability, level, resource, target type, same zone, line of sight, distance and cooldown.
- Server-owned cooldown bookkeeping and per-actor cleanup.
- Status effect model with expiration timestamp.
- Returns a validated effect command, not an immediate HP mutation.

Limitations:
- Not connected to combat RPC, HUD or NetworkPlayer attacks. No playable skills yet.
- When integrated, actor level, class, learned abilities, resources and target visibility MUST come from authoritative server state, not client RPC parameters.
- Status application and expiry processing in the game world remain for later stages.
- Stage 7.7.4 has not started.

Tests:
- Stage 7.7.3: 20/20.
- Classes/SQLite: 21/21.
- Quest persistence: 26/26.
- NPC/network: 15/15.
- Prior combat regression: 20/20.
- Total: 102/102 PASS.
- Godot 4.7.2 headless import passed.
- Android debug APK exported and signature verified, not published.

Production 28740, test 7.6 28766 and test 7.7.2 28777 unchanged.
