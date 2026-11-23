# LunexAutoRpg: screenshot-free first-launch player experience audit

Date: 2026-11-23. Baseline: 2b6ef6a. Method: static scene/script inspection and existing Godot automated tests, **not** a simulated human playthrough. Scores for AGE20, AGE30, AGE37 and BLIND_FIRST_LAUNCH are N/A until actual human or instrumented evidence exists.

## Observations and recommendations

1. **P1, first-launch friction:** `game/network/connect_screen.tscn` asks for server IP, UDP port and character name before entering the game. Default IP and port are populated, but technical fields consume mobile screen space. Recommend default one-tap play with advanced connection settings behind a toggle; preserve direct-IP diagnostics and native `.tscn` editability. Needs product approval before changing UX.
2. **P1, fragile endpoint:** `game/network/connect_screen.gd` and scene hardcode `78.17.214.93:28801`. VPS IP changes will strand existing APKs. Recommend DNS host with documented UDP port, tested resolution and fallback. Requires domain/network approval.
3. **P1, incomplete progression:** `game/progression/progress_hud.gd`, `game/combat/combat_hud.gd` and `game/network/online_world.gd` currently derive only levels 1 and 2 from a 50-XP threshold. This is not a finished RPG level curve. GDD-08.4 owner approval covers smooth leveling without daily caps, but concrete XP curve/cap/pace still need approval before implementation.
4. **P2, mobile ergonomics:** `connect_screen.tscn` sets fixed 354px panel minimum and multiple 40-44px field/button heights. Physical touch-target sizing, landscape clipping, Android keyboard overlap and safe areas have not been verified on a real device.
5. **P2, acceptance gap:** Existing regression tests cover inventory, equipment, catalog, quest data and ENet-related scenarios; they do not prove human comprehension of navigation, quest discoverability, camera, combat readability or delight. Run first-launch device sessions and record time to first quest, first fight, first reward and first equipment change.

## Age-perspective hypotheses, not measured results

- AGE20: speed to combat, visual impact, ability responsiveness and low-friction entry.
- AGE30: clarity of quest goals, reward explanation, quick session resume and UI hierarchy.
- AGE37: legible labels, stable controls, visible progress, easy navigation and predictable automation.

All age-perspective scores: N/A, pending observations. Age is a review lens, not a claim about actual user preferences.

## Next acceptance gates

- Collect Android screenshots or manual observations from real game sessions; do not invent simulated play evidence.
- Owner approves onboarding/endpoint UX changes and XP curve/cap/pace before implementation.
- Keep all visual/UI content native-Godot editable, server authoritative, and external GitHub candidates STUDY/isolated TEST only.
- Validate with Godot headless, ENet tests, Android install, APK signing and GitHub Actions; keep production data backed up.

## Status

Audit observations documented. CONTENT-03 remains IN PROGRESS; this report does not close it or claim a successful manual first-launch test.
