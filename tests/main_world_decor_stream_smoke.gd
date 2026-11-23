extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	var stream: LunexStreamedDecor = world.get_node("StreamedDecor")
	stream.load_radius = 27.0
	stream.hysteresis = 8.0
	stream.update_for_position(Vector3(0, 0, 0))
	assert(stream.loaded_count() == 1, "first marker should stream in")
	stream.update_for_position(Vector3(168, 0, 0))
	assert(stream.loaded_count() == 1, "old marker should stream out and final in")
	assert(world.get_node("Navigation").navigation_mesh != null, "navmesh removed")
	assert(world.get_node("WorldCorridors").get_child_count() == 4, "collision roads removed")
	stream.clear_chunks()
	assert(stream.loaded_count() == 0, "decor chunks not released")
	print("MAIN_WORLD_DECOR_STREAM=PASS actual_instance_load_unload=true server_navmesh_untouched=true roads_untouched=true")
	quit(0)
