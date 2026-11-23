extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://game/network/online_world.tscn") as PackedScene
	assert(packed != null, "main game scene missing")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	var corridors := world.get_node("WorldCorridors")
	assert(corridors.get_child_count() == 4, "four inter-zone corridors required")
	for i in range(4):
		var corridor := corridors.get_child(i) as Node3D
		assert(is_equal_approx(corridor.position.x, float(21 + 42*i)), "wrong corridor position")
		assert(corridor.get_node("RoadBody/RoadShape") is CollisionShape3D, "corridor collision missing")
	for zone in [world.get_node("Navigation/Zone"), world.get_node("Passage/Geometry"), world.get_node("AshGrove/Geometry"), world.get_node("SilentRuins/Geometry"), world.get_node("MistBell/Geometry")]:
		assert(zone.get_node_or_null("EastWall") == null, "blocked eastward traversal")
	assert(world.get_node("Passage/Geometry").get_node_or_null("WestWall") == null, "blocked westward traversal")
	print("MAIN_WORLD_GEOMETRY=PASS four_connected_road_collisions=true open_zone_walls=true native_editable_scenes=true")
	quit(0)
