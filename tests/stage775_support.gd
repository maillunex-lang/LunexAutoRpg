extends SceneTree
var passed := 0

func check(ok: bool, description: String) -> bool:
	if not ok:
		push_error("FAIL: " + description)
		quit(1)
		return false
	passed += 1
	print("PASS: ", description)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var executor := LunexAbilityExecutor.new()
	for id in ["priest_heal", "priest_blessing", "bard_song", "bard_restore"]:
		var skill: LunexAbilityDefinition = load("res://game/combat/abilities/" + id + ".tres")
		if not check(skill != null and skill.is_valid() and skill.ability_id == id, "resource " + id): return
		if not check(executor.register(skill), "register " + id): return
	var a := Vector3.ZERO
	var b := Vector3(3, 0, 0)
	var heal := executor.try_cast(2, "priest", 1, PackedStringArray(["priest_heal"]), 100, "priest_heal", a, b, "ally", true, true, 10000)
	if not check(heal.ok and heal.effect_kind == "heal" and heal.magnitude == 35, "priest heal"): return
	if not check(not executor.try_cast(2, "priest", 1, PackedStringArray(["priest_blessing"]), 100, "priest_blessing", a, b, "ally", true, true, 11000).ok, "priest blessing locked"): return
	var blessing := executor.try_cast(2, "priest", 2, PackedStringArray(["priest_blessing"]), 100, "priest_blessing", a, b, "ally", true, true, 12000)
	if not check(blessing.ok and blessing.status_id == "blessing" and blessing.expires_at_ms == 20000, "priest blessing"): return
	var song := executor.try_cast(3, "bard", 1, PackedStringArray(["bard_song"]), 100, "bard_song", a, a, "self", true, true, 13000)
	if not check(song.ok and song.status_id == "song" and song.expires_at_ms == 21000, "bard song"): return
	if not check(not executor.try_cast(3, "bard", 1, PackedStringArray(["bard_restore"]), 100, "bard_restore", a, b, "ally", true, true, 14000).ok, "bard restore locked"): return
	var restore := executor.try_cast(3, "bard", 2, PackedStringArray(["bard_restore"]), 100, "bard_restore", a, b, "ally", true, true, 15000)
	if not check(restore.ok and restore.magnitude == 22 and restore.resource_left == 85, "bard restore"): return
	if not check(not executor.try_cast(4, "mage", 2, PackedStringArray(["priest_heal"]), 100, "priest_heal", a, b, "ally", true, true, 16000).ok, "cross-class blocked"): return
	if not check(not executor.try_cast(4, "priest", 2, PackedStringArray(["priest_heal"]), 100, "priest_heal", a, b, "enemy", true, true, 16000).ok, "enemy cannot be healed"): return
	if not check(not executor.try_cast(4, "priest", 2, PackedStringArray(["priest_heal"]), 100, "priest_heal", a, Vector3(20,0,0), "ally", true, true, 16000).ok, "heal range enforced"): return
	print("STAGE775_TOTAL=", passed)
	quit()
