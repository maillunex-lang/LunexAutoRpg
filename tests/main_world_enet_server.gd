extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=29047", "--database=user://world_enet_29047.sqlite"]))
	if not world.multiplayer.is_server():
		quit(1)
		return
	var seen := false
	var max_x := -1000.0
	for tick in range(1000):
		await physics_frame
		for peer_id in world._profiles.keys():
			var player := world.players.get_node_or_null(str(peer_id)) as LunexNetworkPlayer
			if player == null:
				continue
			seen = true
			max_x = maxf(max_x, player.global_position.x)
			if player.zone_id != 0 or player.global_position.x > 21.05:
				push_error("ENET_LOCK_BYPASS zone=" + str(player.zone_id) + " x=" + str(player.global_position.x))
				quit(1)
				return

	if seen and max_x <= 21.05 and max_x > 19.0:
		print("MAIN_WORLD_ENET_SERVER=PASS client_seen=true locked_boundary_enforced=true max_x=", max_x)
		quit(0)
		return
	push_error("ENET incomplete: seen=" + str(seen) + " max_x=" + str(max_x))
	quit(1)
