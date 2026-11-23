extends SceneTree

var passed := 0
func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("FAIL: " + message)
		quit(1)
		return false
	passed += 1
	print("PASS: ", message)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var engine := LunexAbilityExecutor.new()
	var ids := ["warrior_strike", "warrior_shield", "mage_bolt", "mage_fireball"]
	for id in ids:
		var skill: LunexAbilityDefinition = load("res://game/combat/abilities/" + id + ".tres")
		if not check(skill != null and skill.is_valid() and skill.ability_id == id, "valid resource " + id): return
		if not check(engine.register(skill), "registered " + id): return
	var a := Vector3.ZERO
	var target := Vector3(2, 0, 0)
	var warrior := engine.try_cast(2, "warrior", 1, PackedStringArray(["warrior_strike"]), 100, "warrior_strike", a, target, "enemy", true, true, 10000)
	if not check(warrior.ok and warrior.magnitude == 35 and warrior.resource_left == 88, "warrior strike damage and energy"): return
	if not check(not engine.try_cast(2, "warrior", 1, PackedStringArray(["warrior_shield"]), 100, "warrior_shield", a, a, "self", true, true, 10000).ok, "warrior shield level lock"): return
	var shield := engine.try_cast(2, "warrior", 2, PackedStringArray(["warrior_shield"]), 100, "warrior_shield", a, a, "self", true, true, 11000)
	if not check(shield.ok and shield.magnitude == 30 and shield.expires_at_ms == 17000, "warrior shield effect"): return
	var bolt := engine.try_cast(3, "mage", 1, PackedStringArray(["mage_bolt"]), 100, "mage_bolt", a, Vector3(5, 0, 0), "enemy", true, true, 12000)
	if not check(bolt.ok and bolt.magnitude == 28, "mage bolt ranged attack"): return
	if not check(not engine.try_cast(3, "mage", 1, PackedStringArray(["mage_fireball"]), 100, "mage_fireball", a, target, "enemy", true, true, 12000).ok, "mage fireball level lock"): return
	var fire := engine.try_cast(3, "mage", 2, PackedStringArray(["mage_fireball"]), 100, "mage_fireball", a, target, "enemy", true, true, 13000)
	if not check(fire.ok and fire.magnitude == 50 and fire.resource_left == 75, "mage fireball"): return
	if not check(not engine.try_cast(3, "mage", 2, PackedStringArray(["warrior_strike"]), 100, "warrior_strike", a, target, "enemy", true, true, 13000).ok, "cross-class exploit blocked"): return
	print("STAGE774_TOTAL=", passed)
	quit()
