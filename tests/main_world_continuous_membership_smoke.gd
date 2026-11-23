extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await physics_frame
	var player_scene := load("res://game/network/network_player.tscn") as PackedScene
	var player := player_scene.instantiate() as LunexNetworkPlayer
	world.add_child(player)
	player.position = Vector3(21.1, 0.3, 0)
	player.velocity = Vector3(1.0, 0, 0)
	var before := player.position
	player.update_zone_without_teleport(1)
	assert(player.zone_id == 1 and player.server_zone_id == 1, "logical zone not updated")
	assert(player.position.distance_to(before) < 0.001, "zone change teleported player")
	assert(player.velocity.x > 0.9, "zone change reset velocity")
	print("MAIN_WORLD_CONTINUOUS_MEMBERSHIP=PASS position_preserved=true velocity_preserved=true logical_zone_updated=true")
	quit(0)
