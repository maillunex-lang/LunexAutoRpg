extends SceneTree

var passed := 0

func verify(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		return false
	passed += 1
	print("PASS: ", message)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var executor := LunexAbilityExecutor.new()
	var skill := LunexAbilityDefinition.new()
	skill.ability_id = "test_strike"
	skill.class_id = "warrior"
	skill.unlock_level = 3
	skill.cooldown_seconds = 2.0
	skill.resource_cost = 5
	skill.max_range = 3.0
	skill.magnitude = 30
	if not verify(executor.register(skill), "register valid skill"): return
	if not verify(not executor.register(skill), "reject duplicate skill"): return
	var learned := PackedStringArray(["test_strike"])
	var a := Vector3.ZERO
	var b := Vector3(2, 0, 0)
	var result := executor.try_cast(2, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", true, true, 10000)
	if not verify(result.ok and result.magnitude == 30 and result.resource_left == 5, "authoritative damage and resource cost"): return
	if not verify(executor.cooldown_until(2, "test_strike") == 12000, "server cooldown stored"): return
	if not verify(not executor.try_cast(2, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", true, true, 10001).ok, "cooldown rejects spam"): return
	if not verify(executor.try_cast(2, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", true, true, 12000).ok, "cast after cooldown"): return
	if not verify(not executor.try_cast(3, "mage", 3, learned, 10, "test_strike", a, b, "enemy", true, true, 13000).ok, "class mismatch rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 2, learned, 10, "test_strike", a, b, "enemy", true, true, 13000).ok, "locked level rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 3, PackedStringArray(), 10, "test_strike", a, b, "enemy", true, true, 13000).ok, "unlearned skill rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 3, learned, 4, "test_strike", a, b, "enemy", true, true, 13000).ok, "resource insufficient"): return
	if not verify(not executor.try_cast(3, "warrior", 3, learned, 10, "test_strike", a, Vector3(4, 0, 0), "enemy", true, true, 13000).ok, "out of range rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", false, true, 13000).ok, "cross-zone rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", true, false, 13000).ok, "hidden target rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 3, learned, 10, "test_strike", a, b, "ally", true, true, 13000).ok, "wrong target type rejected"): return
	if not verify(not executor.try_cast(1, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", true, true, 13000).ok, "invalid actor rejected"): return
	if not verify(not executor.try_cast(3, "warrior", 3, learned, 10, "test_strike", a, Vector3(INF, 0, 0), "enemy", true, true, 13000).ok, "non-finite position rejected"): return
	if not verify(executor.try_cast(3, "warrior", 3, learned, 10, "test_strike", a, b, "enemy", true, true, 13000).ok, "other actor independent"): return
	executor.clear_actor(3)
	if not verify(executor.cooldown_until(3, "test_strike") == 0, "disconnect clears cooldown"): return
	var buff := LunexAbilityDefinition.new()
	buff.ability_id = "test_buff"
	buff.class_id = "bard"
	buff.effect_kind = "status"
	buff.target_kind = "self"
	buff.status_id = "haste"
	buff.status_duration = 5.0
	buff.magnitude = 2
	if not verify(executor.register(buff), "status definition accepted"): return
	var status := executor.try_cast(4, "bard", 1, PackedStringArray(["test_buff"]), 0, "test_buff", a, a, "self", true, true, 20000)
	if not verify(status.ok and status.status_id == "haste" and status.expires_at_ms == 25000, "status expiry authoritative"): return
	print("STAGE773_TOTAL=", passed)
	quit()
