extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	if world.gates.size() != 5 or world.arrivals.size() != 5:
		push_error("Zone gate/arrival mismatch")
		quit(1)
		return
	for i in range(5):
		if world.gates[i] == null or world.arrivals[i] == null:
			push_error("Zone %d missing gate or arrival" % i)
			quit(1)
			return
		if not world.arrivals[i].global_position.is_finite():
			push_error("Invalid arrival")
			quit(1)
			return
	print("STAGE818_ZONE_TOTAL=5")
	world.queue_free()
	quit()
