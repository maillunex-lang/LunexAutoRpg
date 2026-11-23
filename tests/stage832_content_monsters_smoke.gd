extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(0) != OK:
		push_error("Cannot create isolated authoritative ENet server")
		quit(1)
		return
	world.multiplayer.multiplayer_peer = peer
	world.watch.players = world.players
	var player: LunexNetworkPlayer = world._spawn_player([2, world.watch.global_position + Vector3(0.7, 0.0, 0.0), "Tester", "warrior"])
	world.players.add_child(player)
	await physics_frame
	var previous_hp: int = player.health
	world.watch._physics_process(0.6)
	if not world.watch.telegraph_active or not world.watch._provoked:
		push_error("Proactive enemy perception or warning did not activate")
		quit(1)
		return
	world.watch.add_support_threat(2, 10.0)
	if world.watch.primary_threat_peer() != 2:
		push_error("Support threat assignment failed")
		quit(1)
		return
	world.watch._physics_process(world.watch.warning_duration + 0.1)
	if player.health >= previous_hp:
		push_error("Server enemy counterattack did not damage nearby eligible player")
		quit(1)
		return
	print("STAGE832_CONTENT_MONSTERS=PASS proactive_alert telegraph server_damage support_threat ", previous_hp, "->", player.health)
	quit(0)
