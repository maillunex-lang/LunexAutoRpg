extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var ids := {}
	var spawn_ids := {}
	var checked := 0
	for target in world.targets:
		var resource := target.definition as LunexEnemyDefinition
		if resource == null or not resource.is_valid_definition():
			push_error("Missing or invalid editable EnemyDefinition: " + target.name)
			quit(1)
			return
		if resource.enemy_instance_id in ids or resource.spawn_point_id in spawn_ids:
			push_error("Duplicate stable enemy instance/spawn ID")
			quit(1)
			return
		ids[resource.enemy_instance_id] = true
		spawn_ids[resource.spawn_point_id] = true
		if target.target_id != resource.target_id or target.zone_id != resource.zone_id or target.max_health != resource.max_health:
			push_error("Enemy definition incompatible with scene and legacy quest IDs: " + target.name)
			quit(1)
			return
		checked += 1
	if checked != 8:
		push_error("Expected all eight world enemies to have editable definitions")
		quit(1)
		return
	print("STAGE831_ENEMY_DEFINITIONS=PASS unique_instance_ids=", ids.size(), " unique_spawn_ids=",spawn_ids.size(), " legacy_rpc_targets=", checked)
	quit(0)
