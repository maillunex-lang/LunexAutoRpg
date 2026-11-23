extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var second := OS.get_cmdline_user_args().has("--second")
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = "c".repeat(64)
	world._connect_client("127.0.0.1", 29052, "ReconnectTest")
	for tick in range(900):
		await physics_frame
		if not is_instance_valid(world._local_player):
			continue
		var state: Dictionary = world._progress
		if int(state.get("gold", -1)) != 40 or int(state.get("experience", -1)) != 25 or int(state.get("chapter_quests", {}).get("first_steps", {}).get("state", -1)) != LunexProgressStore.Quest.COMPLETE or int(state.get("quests", {}).get("gate_watch", {}).get("quest", -1)) != LunexProgressStore.Quest.COMPLETE:
			continue
		print("MAIN_WORLD_ENET_RECONNECT_CLIENT=PASS second=", second, " progress_received=true")
		quit(0)
		return
	push_error("RECONNECT client progress timeout second=" + str(second))
	quit(1)
