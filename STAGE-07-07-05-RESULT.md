# 7.7.5 - Priest and Bard support skills

Status: implemented in dev, awaiting owner acceptance. Stage 7.7.6 not started.

## Implemented
- Priest Heal: level 1, heals nearest injured living ally in same zone within 7m for 35 HP, 15 energy, 5s cooldown.
- Priest Blessing: level 2, grants nearest living ally in range 5 incoming-damage reduction for 8s, 20 energy, 12s cooldown.
- Bard Battle Song: level 1, grants all living allies in caster's zone within 6m 3 incoming-damage reduction for 8s, 20 energy, 10s cooldown.
- Bard Restoration: level 2, heals nearest injured living ally within 7m for 22 HP, 15 energy, 7s cooldown.
- The four skill definitions are editable Godot Resources. Combat HUD shows localized names, level locks and energy.
- Server chooses ally from current players; client cannot submit arbitrary ally peer ID. Server validates class, learned skill, level, energy, cooldown, target type, zone and range.
- Support effects use existing server-side health state; healing is capped at max HP, cannot revive a dead ally, and defensive effects expire based on monotonic server ticks.

## Boundaries and known limitations
- Initial numeric balance only; not final GDD tuning.
- No manual ally selection yet: healing prioritizes the nearest injured living player. If none is injured, healing is rejected without energy expenditure.
- Damage-reduction effects are not visualized yet; HUD does not show cooldown timers.
- Only damage taken via NetworkPlayer.take_counter_damage is reduced by support effects.
- Status stacking currently uses max strength and replaces expiry; no separate per-source stacking.
- Android two-client support gameplay has not yet been manually verified.
- Production and existing test services have not been changed.

## Verification
- 17/17 new support ability checks.
- 15/15 Warrior/Mage checks.
- 20/20 ability engine checks.
- 21/21 class/SQLite.
- 26/26 quests/SQLite.
- 15/15 NPC/network.
- 20/20 earlier combat regression.
- Total **134/134 automated checks PASS**.
- Godot 4.7.2 headless editor import: success; Android debug APK export and signature verification: success.

Awaiting owner acceptance of 7.7.5. Stage 7.7.6 not started.
