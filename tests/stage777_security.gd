extends SceneTree

var passed := 0
func check(value: bool, name: String) -> bool:
	if not value:
		push_error("FAIL: " + name)
		quit(1)
		return false
	passed += 1
	print("PASS: ", name)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var executor := LunexAbilityExecutor.new()
	var names := ["warrior_strike", "warrior_shield", "mage_bolt", "mage_fireball", "priest_heal", "priest_blessing", "bard_song", "bard_restore"]
	for name in names:
		var ability: LunexAbilityDefinition = load("res://game/combat/abilities/" + name + ".tres")
		if not check(ability != null and ability.is_valid(), "balanced definition " + name): return
		if not check(executor.register(ability), "registered " + name): return
	var pos := Vector3.ZERO
	var near := Vector3(1, 0, 0)
	var learned := PackedStringArray(["warrior_strike"])
	var first := executor.try_cast(7, "warrior", 1, learned, 100, "warrior_strike", pos, near, "enemy", true, true, 10000)
	if not check(first.ok and first.resource_left == 88, "valid server cast"): return
	if not check(executor.try_cast(7, "warrior", 1, learned, 100, "warrior_strike", pos, near, "enemy", true, true, 10001).reason == "cooldown", "spam cooldown blocked"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 0, "warrior_strike", pos, near, "enemy", true, true, 10000).reason == "no_resource", "zero energy blocked"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, -1, "warrior_strike", pos, near, "enemy", true, true, 10000).reason == "invalid_actor", "negative energy blocked"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 1000, "warrior_strike", pos, near, "enemy", true, true, 10000).reason == "invalid_actor", "inflated energy blocked"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 100, "warrior_strike", pos, near, "enemy", false, true, 10000).reason == "invalid_target", "zone isolation"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 100, "warrior_strike", pos, near, "enemy", true, false, 10000).reason == "invalid_target", "line of sight"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 100, "warrior_strike", pos, Vector3(100,0,0), "enemy", true, true, 10000).reason == "invalid_target", "range exploit"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 100, "warrior_strike", pos, near, "self", true, true, 10000).reason == "invalid_target", "wrong target type"): return
	if not check(executor.try_cast(8, "mage", 1, learned, 100, "warrior_strike", pos, near, "enemy", true, true, 10000).reason == "not_learned", "class spoof"): return
	if not check(executor.try_cast(8, "warrior", 1, PackedStringArray(), 100, "warrior_strike", pos, near, "enemy", true, true, 10000).reason == "not_learned", "unlearned ability"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 100, "missing", pos, near, "enemy", true, true, 10000).reason == "not_learned", "unknown ability"): return
	if not check(executor.try_cast(8, "warrior", 1, learned, 100, "warrior_strike", Vector3(INF,0,0), near, "enemy", true, true, 10000).reason == "invalid_actor", "invalid coordinates"): return
	if not check(executor.try_cast(1, "warrior", 1, learned, 100, "warrior_strike", pos, near, "enemy", true, true, 10000).reason == "invalid_actor", "server peer rejected"): return
	if not check(executor.cooldown_until(7, "warrior_strike") > 10000, "cooldown retained"): return
	executor.clear_actor(7)
	if not check(executor.cooldown_until(7, "warrior_strike") == 0, "disconnect clears cooldown"): return
	var after := executor.try_cast(7, "warrior", 1, learned, 100, "warrior_strike", pos, near, "enemy", true, true, 10001)
	if not check(after.ok, "reconnect fresh cooldown"): return
	print("STAGE777_TOTAL=", passed)
	quit()
