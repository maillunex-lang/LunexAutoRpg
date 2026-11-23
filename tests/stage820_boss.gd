extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var boss := world.get_node("MistBellGuardian") as LunexGateWatch
	if boss == null or boss.zone_id != 4 or boss.max_health < 200 or boss.warning_duration < 1.0 or boss.counter_radius < 2.0 or boss.players != null:
		push_error("Boss scene invalid")
		quit(1)
		return
	if not world.targets.has(boss):
		push_error("Boss not registered")
		quit(1)
		return
	print("STAGE820_BOSS_TOTAL=2")
	world.queue_free()
	quit()
