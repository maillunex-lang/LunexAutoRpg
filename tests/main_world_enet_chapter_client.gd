extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = Crypto.new().generate_random_bytes(32).hex_encode()
	world._connect_client("127.0.0.1", 29050, "CrossZoneENet")
	var seen := false
	var requested := false
	var interacted := false
	for tick in range(2600):
		await physics_frame
		if not is_instance_valid(world._local_player):
			continue
		seen = true
		if not requested and tick > 40:
			world._request_quest_route.rpc_id(1, "scout_contact")
			requested = true
		if requested and world._local_player.zone_id == 1 and world._local_player.global_position.distance_to(Vector3(43, 0, 2)) < 2.8 and not interacted:
			world._request_npc.rpc_id(1, "scout")
			interacted = true
		if interacted and int(world._progress.get("chapter_quests", {}).get("scout_contact", {}).get("state", 0)) == LunexProgressStore.Quest.COMPLETE:
			print("MAIN_WORLD_ENET_CHAPTER_CLIENT=PASS quest_route_rpc=true npc_interaction_rpc=true quest_reward_state=true")
			quit(0)
			return

	push_error("ENET client never spawned=" + str(seen))
	quit(1)
