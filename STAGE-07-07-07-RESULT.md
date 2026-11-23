# 7.7.7 - Balance guardrails, anti-cheat and regression

Status: implemented in development, awaiting owner acceptance. Stage 7.7.8 not started.

## Implemented
- Hardened the server-side ability executor against negative or inflated energy values, nonfinite positions, invalid peer IDs, class spoofing, unlearned abilities, wrong target types, cross-zone casts, out-of-range casts, blocked line of sight, and cooldown spam.
- Added validation of configured resource limits for skill cost, magnitude, duration, range and cooldown.
- Added server-side line-of-sight validation for allied targets as well as enemies. Skill data (class, level and learned skills) remains sourced from server SQLite; clients never send damage or healing values.
- Cleared shield/blessing expiration timestamps on player respawn, preventing stale status carryover.
- Added a dedicated anti-cheat regression suite covering 33 checks, including cooldown reset on disconnect.
- Reviewed current preliminary class skill parameters and retained them without unapproved rebalancing. The full RPG level curve and PvP balance are not yet designed or accepted.

## Verification
- New anti-cheat tests: 33/33.
- Stage 7.7.6 HUD: 12/12.
- Stage 7.7.5 support: 17/17.
- Stage 7.7.4 warrior/mage: 15/15.
- Stage 7.7.3 executor: 20/20.
- Classes/SQLite: 21/21.
- Quests/SQLite: 26/26.
- NPC/network: 15/15.
- Previous combat: 20/20.
- Total: **179/179 PASS**.
- Godot 4.7.2 headless editor import: PASS.
- Android debug APK export: PASS; Android signature verified, 58 MB.

## Limitations
- These are automated tests, not a penetration test or comprehensive anti-cheat certification.
- Live multi-client casting, healing, HUD and VFX have not yet been manually tested on Android.
- No production server or existing test service was restarted, and no public APK was replaced.
- Stage 7.7.8 isolated deployment and manual acceptance remain for a separate authorization.
