extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	for i in range(12):
		await physics_frame
	var physics: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var obstacles: Array[Vector3] = [Vector3(4, 0, 0), Vector3(39, 0, 0)]
	var hits := 0
	for point in obstacles:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3(0, 1.1, 0), point + Vector3(0, 0.25, 0))
		if not physics.intersect_ray(query).is_empty():
			hits += 1
	assert(hits == 2, "Expected real collision obstacles in proposed straight route; hits=%d" % hits)
	print("MAIN_WORLD_OBSTACLE_GUARD=PASS straight_nav_strip_unsafe=true detected_collision_points=2")
	quit(0)
