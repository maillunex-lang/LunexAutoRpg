extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=29048", "--database=user://world_enet_29048.sqlite"]))
	if not world.multiplayer.is_server():
		quit(1)
		return
	var seen := false
	var max_x := -1000.0
	var seeded := false
	var crossed := false
	for tick in range(1000):
		await physics_frame
		for peer_id in world._profiles.keys():
			var player := world.players.get_node_or_null(str(peer_id)) as LunexNetworkPlayer
			if player == null:
				continue
			seen = true
			if not seeded:
				var profile: String = world._profiles[peer_id]
				if not world._store._db.query_with_bindings("INSERT OR REPLACE INTO quest_progress (profile, quest_id, state) VALUES (?, ?, ?)", [profile, "gate_watch", LunexProgressStore.Quest.COMPLETE]):
					push_error("Failed to seed completed gate quest")
					quit(1)
					return
				seeded = true
			max_x = maxf(max_x, player.global_position.x)
			if player.zone_id == 1 and player.global_position.x > 21.1:
				crossed = true
				if tick > 620:
					print("MAIN_WORLD_ENET_UNLOCKED_SERVER=PASS real_enet_crossing=true zone=1 x=", player.global_position.x)
					quit(0)
					return

	if crossed:
		print("MAIN_WORLD_ENET_UNLOCKED_SERVER=PASS client_seen=true locked_boundary_enforced=true max_x=", max_x)
		quit(0)
		return
	push_error("ENET unlocked crossing incomplete: seen=" + str(seen) + " max_x=" + str(max_x))
	quit(1)
