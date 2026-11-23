extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tag := "alpha"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--client="):
			tag = arg.trim_prefix("--client=")
	var is_alpha := tag == "alpha"
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = ("a" if is_alpha else "b").repeat(64)
	world._connect_client("127.0.0.1", 28992, "Test_" + tag)
	var joined := false
	for tick in range(600):
		await process_frame
		if is_instance_valid(world._local_player) and not world._progress.is_empty():
			joined = true
			break
	if not joined:
		push_error("TWO_CLIENT_%s: join failed: %s" % [tag, world.screen.status.text])
		quit(1)
		return
	print("TWO_CLIENT_%s_JOIN=PASS peer=%s" % [tag, str(world.multiplayer.get_unique_id())])
	world._choose_class.rpc_id(1, "warrior" if is_alpha else "mage")
	for tick in range(180):
		await process_frame
		if str(world._progress.get("class_id", "")) == ("warrior" if is_alpha else "mage"):
			break
	world._request_auto.rpc_id(1, true, 0)
	var attacker := false
	for tick in range(1100):
		await process_frame
		if world._local_player.attack_sequence > 0:
			attacker = true
			break
	if not attacker:
		push_error("TWO_CLIENT_%s: no server-authoritative attack sequence" % tag)
		quit(1)
		return
	print("TWO_CLIENT_%s_ATTACK=PASS sequence=%d" % [tag, world._local_player.attack_sequence])
	quit(0)
