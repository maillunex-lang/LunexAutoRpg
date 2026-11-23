class_name LunexAutoSafety
extends RefCounted

# Server-side policy: never trust the client to permit automatic actions.
static func allow_auto(alive: bool, in_pvp: bool, dangerous_boss_phase: bool, enemy_valid: bool) -> bool:
	return alive and enemy_valid and not in_pvp and not dangerous_boss_phase
