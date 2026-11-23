class_name LunexAbilityExecutor
extends RefCounted

# Server-only ability validation and resolution. No client-supplied damage or cooldown.
# Effects are returned as a command for the authoritative world to apply in stage 7.7.4+.
var _definitions: Dictionary = {}
var _cooldowns: Dictionary = {}
var _effects: Dictionary = {}

func register(definition: LunexAbilityDefinition) -> bool:
	if definition == null or not definition.is_valid() or _definitions.has(definition.ability_id):
		return false
	_definitions[definition.ability_id] = definition
	return true

func try_cast(actor_id: int, actor_class: String, actor_level: int, learned_ids: PackedStringArray, resource: int, ability_id: String, actor_position: Vector3, target_position: Vector3, target_kind: String, same_zone: bool, visible: bool, now_ms: int) -> Dictionary:
	if actor_id < 2 or now_ms < 0 or resource < 0 or resource > 100 or not actor_position.is_finite() or not target_position.is_finite():
		return {"ok": false, "reason": "invalid_actor"}
	var definition: LunexAbilityDefinition = _definitions.get(ability_id)
	if definition == null or definition.class_id != actor_class or actor_level < definition.unlock_level or not learned_ids.has(ability_id):
		return {"ok": false, "reason": "not_learned"}
	if not same_zone or not visible or definition.target_kind != target_kind or actor_position.distance_squared_to(target_position) > definition.max_range * definition.max_range:
		return {"ok": false, "reason": "invalid_target"}
	if resource < definition.resource_cost:
		return {"ok": false, "reason": "no_resource"}
	var key := "%d:%s" % [actor_id, ability_id]
	if now_ms < int(_cooldowns.get(key, 0)):
		return {"ok": false, "reason": "cooldown"}
	_cooldowns[key] = now_ms + ceili(definition.cooldown_seconds * 1000.0)
	var result := {"ok": true, "effect_kind": definition.effect_kind, "target_kind": definition.target_kind, "magnitude": definition.magnitude, "resource_left": resource - definition.resource_cost, "cooldown_until_ms": _cooldowns[key]}
	if definition.effect_kind == "status":
		var effect := LunexStatusEffect.new(definition.status_id, now_ms + ceili(definition.status_duration * 1000.0), definition.magnitude)
		_effects["%d:%s" % [actor_id, definition.status_id]] = effect
		result["status_id"] = effect.effect_id
		result["expires_at_ms"] = effect.expires_at_ms
	return result

func cooldown_until(actor_id: int, ability_id: String) -> int:
	return int(_cooldowns.get("%d:%s" % [actor_id, ability_id], 0))

func clear_actor(actor_id: int) -> void:
	var prefix := str(actor_id) + ":"
	for key in _cooldowns.keys():
		if str(key).begins_with(prefix):
			_cooldowns.erase(key)
	for key in _effects.keys():
		if str(key).begins_with(prefix):
			_effects.erase(key)
