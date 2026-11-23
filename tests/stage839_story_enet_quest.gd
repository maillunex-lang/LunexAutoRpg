extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = "f".repeat(64)
	world._connect_client("127.0.0.1", 28994, "QuestTester")
	for i in range(420):
		await process_frame
		if is_instance_valid(world._local_player) and not world._progress.is_empty():
			break
	if not is_instance_valid(world._local_player) or world._progress.is_empty():
		push_error("STAGE839: login failed")
		quit(1)
		return
	world._request_quest_route.rpc_id(1, "first_steps")
	for i in range(240):
		await process_frame
		if world.zone_hud.notice.text.contains("Наставник"):
			break
	if not world.zone_hud.notice.text.contains("Наставник"):
		push_error("STAGE839: no NPC route")
		quit(1)
		return
	# The spawn is already close to the mentor; testing unauthorized future quest instead.
	world._chapter_accept.rpc_id(1, "chapter_finale")
	for i in range(80):
		await process_frame
	if world._progress.get("chapter_quests", {}).has("chapter_finale"):
		push_error("STAGE839: accepted future story quest without prerequisites")
		quit(1)
		return
	print("STAGE839_QUEST_SERVER=PASS join giver_route unauthorized_future_quest_rejected")
	quit(0)
