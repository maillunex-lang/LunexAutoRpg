extends SceneTree
var checks := 0
func verify(ok: bool, label: String) -> bool:
	if not ok:
		push_error("FAIL " + label)
		quit(1)
		return false
	checks += 1
	print("PASS ", label)
	return true
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	if not verify(world.multiplayer.is_server(), "Isolated world uses authoritative server API"): return
	world.set_server_auto_context(101, true, false)
	if not verify(world._pvp_instances.get(101) == true, "PvP context registered server-side"): return
	world.set_server_auto_context(101, false, true)
	if not verify(world._dangerous_boss_phases.get(101) == true, "Dangerous boss context registered"): return
	if not verify(not LunexAutoSafety.allow_auto(true, false, true, true), "Dangerous boss blocks auto combat"): return
	world.set_server_auto_context(101, false, false)
	if not verify(not world._pvp_instances[101] and not world._dangerous_boss_phases[101], "Context resets"): return
	world.queue_free()
	print("STAGE816_AUTO_CONTEXT_TOTAL=", checks)
	quit()
