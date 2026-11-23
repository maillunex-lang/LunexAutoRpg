extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	var streamer: LunexWorldVisualStreamer = world.get_node("WorldVisualStreamer")
	streamer.view_distance = 70.0
	streamer.update_for_position(Vector3(0, 0, 0))
	assert(world.get_node("Navigation/Zone").visible, "starting zone should be visible")
	assert(world.get_node("Passage/Geometry").visible, "adjacent zone should be previsible")
	assert(not world.get_node("MistBell/Geometry").visible, "distant geometry should be culled")
	assert(world.get_node("MistBell").navigation_mesh != null, "culling removed server navmesh")
	streamer.update_for_position(Vector3(168, 0, 0))
	assert(world.get_node("MistBell/Geometry").visible, "destination geometry did not appear")
	assert(not world.get_node("Navigation/Zone").visible, "distant starting geometry not culled")
	streamer.show_all()
	assert(world.get_node("Navigation/Zone").visible and world.get_node("MistBell/Geometry").visible, "restore all failed")
	print("MAIN_WORLD_VISUAL_STREAMING=PASS culling=true restore=true navmesh_preserved=true")
	quit(0)
