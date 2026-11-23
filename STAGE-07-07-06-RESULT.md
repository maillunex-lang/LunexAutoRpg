# 7.7.6 - Auto-combat priority, manual HUD, procedural VFX

**Status:** implemented in dev, awaiting owner acceptance. Stage 7.7.7 not started.

## Implemented
- On successful manual skill cast, server temporarily gives the skill priority over automatic attacks for 0.45 seconds. Auto mode remains enabled and resumes after this window; failed casts do not interrupt auto combat.
- The combat HUD now displays a local skill cooldown countdown and disables skill buttons until the cooldown expires. Cooldowns remain enforced on the authoritative server. HUD resets on disconnect.
- A short transparent colored ColorRect pulse (Godot Tween) indicates a successful skill. No new textures, particles or heavy shaders; no change to character animation pipeline.
- Server sends only the accepted cooldown duration in skill feedback; client display is cosmetic and cannot bypass server validation.

## Limits
- This is an initial simple HUD VFX, not full 3D skill effects. Rich class-specific VFX are deferred.
- The 0.45-second manual priority is preliminary tuning, not final balance.
- Skill feedback and countdown have not been manually tested on Android or on two simultaneous clients.
- No server or published APK was updated.

## Checks
- 12/12 new stage 7.7.6 HUD checks.
- 17/17 stage 7.7.5.
- 15/15 stage 7.7.4.
- 20/20 stage 7.7.3.
- 21/21 class/SQLite.
- 26/26 quest/SQLite.
- 15/15 NPC/network.
- 20/20 previous combat.
- **146/146 automated checks PASS**.
- Godot 4.7.2 headless editor import PASS; Android debug APK export PASS; apksigner verification PASS.
- Auto-attack interruption behavior still requires an end-to-end server/client gameplay test.

**Stage 7.7.7 not started.**
