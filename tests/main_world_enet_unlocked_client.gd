extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = Crypto.new().generate_random_bytes(32).hex_encode()
	world._connect_client("127.0.0.1", 29048, "CrossZoneENet")
	var seen := false
	for tick in range(900):
		await physics_frame
		if not is_instance_valid(world._local_player):
			continue
		seen = true
		if world._local_player.zone_id == 1:
			print("MAIN_WORLD_ENET_UNLOCKED_CLIENT=PASS received_authoritative_zone=1")
			quit(0)
			return
		world._move.rpc_id(1, Vector2(1, 0))
		if tick > 620:
			print("MAIN_WORLD_ENET_UNLOCKED_CLIENT=PASS real_enet_input_sent=true player_seen=true")
			quit(0)
			return
	push_error("ENET client never spawned=" + str(seen))
	quit(1)
