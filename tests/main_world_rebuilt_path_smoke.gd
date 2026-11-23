extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	for i in range(80):
		await physics_frame
	var map: RID = world.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, Vector3(0, 0.2, 0), Vector3(168, 0.2, 0), true)
	assert(path.size() >= 2, "no world path")
	assert(path[0].distance_to(Vector3(0, 0.2, 0)) < 3 and path[-1].distance_to(Vector3(168, 0.2, 0)) < 3, "path endpoints disconnected")
	var physics: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var blocked := 0
	var first_block := Vector3.ZERO
	for i in range(path.size() - 1):
		var a: Vector3 = path[i]
		var b: Vector3 = path[i+1]
		var samples := maxi(1, ceili(a.distance_to(b) / 0.2))
		for j in range(samples+1):
			var point := a.lerp(b, float(j)/samples)
			var hit: Dictionary = physics.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3(0, 1.1, 0), point+Vector3(0, 0.25, 0)))
			if not hit.is_empty():
				blocked += 1
				if first_block == Vector3.ZERO:
					first_block = point
	print("REBUILT_PATH_DIAGNOSTIC points=", path.size(), " collision_samples=", blocked, " first_block=", first_block)
	assert(blocked == 0, "navmesh path intersects physical obstacles")
	print("MAIN_WORLD_REBUILT_PATH=PASS connected=true collision_free=true")
	quit(0)
