extends SceneTree

var passed := 0
func check(value: bool, label: String) -> bool:
	if not value:
		push_error("FAIL: " + label)
		quit(1)
		return false
	passed += 1
	print("PASS: ", label)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud: LunexCombatHUD = load("res://game/combat/combat_hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	if not check(hud.has_node("SkillFlash"), "procedural skill pulse exists"): return
	if not check(not hud.get_node("SkillFlash").visible, "pulse hidden initially"): return
	hud.refresh_skills("mage", 0, 100.0)
	if not check(not hud.get_node("Actions/SkillOne").disabled, "first mage skill unlocked"): return
	if not check(hud.get_node("Actions/SkillTwo").disabled, "second mage skill level locked"): return
	hud.show_skill_feedback("ok:mage_bolt", 2200)
	if not check(hud.get_node("SkillFlash").visible, "successful skill pulse shown"): return
	hud.refresh_skills("mage", 0, 100.0)
	if not check(hud.get_node("Actions/SkillOne").disabled, "local cooldown disables button"): return
	hud.show_skill_feedback("cooldown", 0)
	if not check(hud.get_node("Actions/SkillOne").disabled, "rejection does not reset cooldown"): return
	hud.reset_skill_ui()
	hud.refresh_skills("mage", 0, 100.0)
	if not check(not hud.get_node("Actions/SkillOne").disabled, "disconnect resets cooldown"): return
	if not check(not hud.get_node("SkillFlash").visible, "disconnect clears pulse"): return
	hud.refresh_skills("priest", 0, 100.0)
	if not check(hud.get_node("Actions/SkillOne").visible, "priest skill remains visible"): return
	hud.refresh_skills("bard", 0, 100.0)
	if not check(hud.get_node("Actions/SkillOne").visible, "bard skill remains visible"): return
	hud.refresh_skills("warrior", 0, 100.0)
	if not check(hud.get_node("Actions/SkillTwo").disabled, "warrior second skill locked"): return
	hud.queue_free()
	print("STAGE776_TOTAL=", passed)
	quit()
