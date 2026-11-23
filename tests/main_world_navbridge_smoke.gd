extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	for i in range(60):
		await physics_frame
	var map: RID = world.get_world_3d().navigation_map
	var passed := 0
	for i in range(4):
		var corridor := world.get_node("WorldCorridors/Corridor%d" % (i + 1))
		assert(corridor.get_node("Navigation").navigation_mesh != null, "missing bridge navigation")
		var start := Vector3(float(i * 42 + 7), 0.2, 0)
		var finish := Vector3(float(i * 42 + 35), 0.2, 0)
		var route := NavigationServer3D.map_get_path(map, start, finish, true)
		if route.size() >= 2 and route[0].distance_to(start) < 3.0 and route[-1].distance_to(finish) < 3.0:
			passed += 1
	assert(passed == 4, "not all corridors support navigation path: %d" % passed)
	var full_route := NavigationServer3D.map_get_path(map, Vector3(0, 0.2, 0), Vector3(168, 0.2, 0), true)
	var full_connected := full_route.size() >= 2 and full_route[0].distance_to(Vector3(0, 0.2, 0)) < 4.0 and full_route[-1].distance_to(Vector3(168, 0.2, 0)) < 4.0
	print("MAIN_WORLD_NAVBRIDGE=PASS four_navigation_bridge_paths=true full_world_path=" + str(full_connected) + " (diagnostic)")
	quit(0)
