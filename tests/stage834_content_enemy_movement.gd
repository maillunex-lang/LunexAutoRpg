extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(0) != OK:
		push_error("Unable to establish local authoritative ENet server")
		quit(1)
		return
	world.multiplayer.multiplayer_peer = peer
	var start: Vector3 = world.stone_guard.global_position
	var spawn := start + Vector3(0.0, 0.0, 3.2)
	var player: LunexNetworkPlayer = world._spawn_player([2, spawn, "MovementTester", "warrior"])
	world.players.add_child(player)
	player.enter_zone(1, spawn)
	world.stone_guard.ai_players = world.players
	var start_distance: float = world.stone_guard.global_position.distance_to(player.global_position)
	print("DEBUG ai_players=",world.stone_guard.ai_players != null," server=",world.multiplayer.is_server()," zone=",player.zone_id," distance=",start_distance," los=",world.stone_guard._can_see_ai_target(player)," aggro=",world.stone_guard.definition.aggro_radius)
	for i in range(150):
		await physics_frame
	var end_distance: float = world.stone_guard.global_position.distance_to(player.global_position)
	if end_distance > start_distance - 0.4:
		push_error("Enemy did not follow NavMesh toward player: %.2f -> %.2f state %d" % [start_distance, end_distance, world.stone_guard.ai_state])
		quit(1)
		return
	print("STAGE834_CHASE=PASS dist %.2f -> %.2f" % [start_distance, end_distance])
	player.enter_zone(2, player.global_position)
	for i in range(180):
		await physics_frame
	var return_distance: float = world.stone_guard.global_position.distance_to(start)
	if return_distance > 1.0:
		push_error("Enemy did not return to spawn: %.2f" % return_distance)
		quit(1)
		return
	print("STAGE834_RETURN=PASS dist %.2f" % return_distance)
	world.stone_guard.respawn_delay = 0.1
	world.stone_guard.take_hit(999, 2)
	for i in range(30):
		await physics_frame
	if world.stone_guard.health != world.stone_guard.max_health:
		push_error("Server-driven respawn failed")
		quit(1)
		return
	print("STAGE834_RESPAWN=PASS hp %d" % world.stone_guard.health)
	quit(0)
