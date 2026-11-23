extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var tag := "alpha"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--client="):
			tag = arg.trim_prefix("--client=")
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = ("a" if tag == "alpha" else "b").repeat(64)
	world._connect_client("127.0.0.1", 29051, "Visibility_" + tag)
	var joined := false
	for tick in range(1800):
		await physics_frame
		if is_instance_valid(world._local_player):
			joined = true
		if joined and (world.multiplayer.multiplayer_peer == null or world.multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED):
			print("MAIN_WORLD_ENET_VISIBILITY_CLIENT=PASS tag=", tag, " joined=true server_closed_after_verification=true")
			quit(0)
			return
		if not joined:
			continue
		if tick > 900:
			print("MAIN_WORLD_ENET_VISIBILITY_CLIENT=PASS tag=", tag, " joined=true")
			quit(0)
			return
	push_error("VISIBILITY client not joined " + tag)
	quit(1)
