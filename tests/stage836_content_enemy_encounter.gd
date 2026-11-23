extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(0) != OK:
		push_error("No server")
		quit(1)
		return
	world.multiplayer.multiplayer_peer = peer
	var stone: LunexTrainingEnemy = world.stone_guard
	var spawn := stone.global_position + Vector3(0.0, 0.0, 1.2)
	var player: LunexNetworkPlayer = world._spawn_player([2, spawn, "GuardTest", "warrior"])
	world.players.add_child(player)
	player.enter_zone(1, spawn)
	stone.ai_players = world.players
	var saw_windup := false
	for tick in range(180):
		await physics_frame
		if stone.ai_warning_active:
			saw_windup = true
		if player.health < player.max_health and saw_windup:
			break
	if not saw_windup or player.health >= player.max_health:
		push_error("No warned server-driven enemy melee: warning=%s hp=%d" % [str(saw_windup), player.health])
		quit(1)
		return
	print("STAGE836_MELEE=PASS warning=%s damage=%d" % [str(saw_windup), player.max_health - player.health])
	player.enter_zone(3, player.global_position)
	var patroller: LunexTrainingEnemy = world.mist_hunter
	patroller.ai_players = world.players
	var home: Vector3 = patroller.global_position
	var max_displacement := 0.0
	for tick in range(200):
		await physics_frame
		max_displacement = maxf(max_displacement, patroller.global_position.distance_to(home))
	if max_displacement < 0.2:
		push_error("Editor-authored patrol failed to move %.3f" % max_displacement)
		quit(1)
		return
	print("STAGE836_PATROL=PASS max_displacement=%.2f" % max_displacement)
	quit(0)
