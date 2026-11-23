extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("STAGE832_FAIL: " + message)
	quit(1)

func _run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	var server := ENetMultiplayerPeer.new()
	if server.create_server(0) != OK:
		_fail("Create server")
		return
	world.multiplayer.multiplayer_peer = server
	var enemy := world.get_node("AshWanderer") as LunexGateWatch
	enemy.players = world.players
	var player: LunexNetworkPlayer = world._spawn_player([2, enemy.global_position + Vector3(1.0, 0.1, 0.0), "AI tester", "warrior"])
	world.players.add_child(player)
	player.enter_zone(enemy.zone_id, enemy.global_position + Vector3(1.0, 0.1, 0.0))
	for i in range(40):
		await physics_frame
	if not enemy._provoked or enemy.brain_state == LunexGateWatch.BrainState.IDLE:
		_fail("Server aggression did not activate near player")
		return
	enemy._register_threat(2)
	enemy.add_support_threat(3, 10.0)
	if enemy.primary_threat_peer() != 3:
		_fail("Support contribution did not affect threat ordering")
		return
	enemy._reset_counter()
	player.enter_zone(1, enemy.global_position + Vector3(0.5, 0, 0))
	for i in range(36):
		await physics_frame
	if enemy._provoked:
		_fail("Enemy should ignore players in another zone")
		return
	enemy._register_threat(2)
	player.enter_zone(0, Vector3(30, 0, 30))
	enemy._disengage_left = enemy.disengage_delay
	for i in range(36):
		await physics_frame
	if enemy._provoked or not enemy._threat.is_empty():
		_fail("Leash disengage must clear threat")
		return
	print("STAGE832_ENEMY_SERVER_BRAIN=PASS proximity_aggro support_threat zone_isolation leash_reset")
	quit(0)
