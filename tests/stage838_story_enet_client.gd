extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = "d".repeat(64)
	world._connect_client("127.0.0.1", 28993, "StorySmoke")
	for i in range(350):
		await process_frame
		if is_instance_valid(world._local_player) and not world._progress.is_empty():
			break
	if not is_instance_valid(world._local_player) or world._progress.is_empty():
		push_error("STAGE838 story ENet login failed")
		quit(1)
		return
	world._request_quest_route.rpc_id(1, "first_steps")
	for i in range(200):
		await process_frame
		if world.zone_hud.notice.text.contains("Наставник"):
			break
	if not world.zone_hud.notice.text.contains("Наставник"):
		push_error("STAGE838 no server verified quest giver route notice: " + world.zone_hud.notice.text)
		quit(1)
		return
	print("STAGE838_STORY_ROUTE=PASS peer=",world.multiplayer.get_unique_id()," notice=",world.zone_hud.notice.text)
	quit(0)
