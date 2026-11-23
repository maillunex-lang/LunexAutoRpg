# 7.7.4 - Warrior and Mage combat abilities

Status: implemented in dev, awaiting owner acceptance. Stage 7.7.5 not started.

## Implemented
- Four configurable Godot abilities: warrior_strike (level 1, 35 damage, 12 energy, 3 s cooldown), warrior_shield (level 2, 30 absorption, 6 s duration, 20 energy, 10 s cooldown), mage_bolt (level 1, 28 damage, 10 energy, 2 s cooldown, 6 m range), mage_fireball (level 2, 50 damage, 25 energy, 7 s cooldown, 6 m range). Numbers are initial test balance, not final approval.
- Server RPC request_skill: identifies sender from multiplayer peer, reads class and XP from server-side SQLite, validates class/learned skills, target, range, line of sight, zone, resource and cooldown through stage 7.7.3 engine. Client supplies only ability ID and target index.
- Server applies damage to training targets (including existing quest hit accounting), and absorbs counter-damage with the warrior shield. Energy regenerates on the server at 5 per second and resets on respawn.
- Godot-editable skill buttons in combat HUD, showing current level lock and energy. Successful attacks use existing attack animation. Feedback RPC shows result and current energy.

## Limitations
- Four of the planned Warrior/Mage abilities are now playable; additional skill effects and visuals remain for later design and tuning.
- Level progression currently has only level 1 and level 2 based on 50 XP, consistent with existing game.
- Cooldown is server-enforced but HUD does not yet display a countdown; errors appear as text. Advanced VFX not yet implemented.
- End-to-end manual test of casting and shield on Android has NOT been completed. Android APK is a locally built debug artifact only.
- Existing server services and published APK were not updated.

## Checks
- 15/15 new Warrior/Mage resource and executor checks.
- 20/20 stage 7.7.3 checks.
- 21/21 class/SQLite.
- 26/26 quests.
- 15/15 NPC/network.
- 20/20 earlier combat regression.
- 117/117 automated checks passed. Godot 4.7.2 headless editor import and Android debug export/signature passed.
- Manual Android gameplay and two-client network casting require acceptance testing.

Stage 7.7.5 not started.
