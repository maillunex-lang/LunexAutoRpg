extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = Crypto.new().generate_random_bytes(32).hex_encode()
	world._connect_client("127.0.0.1", 28995, "FullStoryTest")
	for i in range(600):
		await process_frame
		if is_instance_valid(world._local_player) and not world._progress.is_empty():
			break
	if not is_instance_valid(world._local_player) or world._progress.is_empty():
		push_error("STAGE843 client did not join")
		quit(1)
		return
	print("STAGE843_CONNECTED peer=",world.multiplayer.get_unique_id())
	var completed := 0
	for q in world.chapter_quest_definitions:
		var giver: LunexNpcActor = world._chapter_giver(q)
		var target: LunexTrainingEnemy
		if not q.objective_enemy_id.is_empty():
			for candidate in world.targets:
				if candidate.target_id == q.objective_enemy_id:
					target = candidate
					break
		var desired: Vector3 = giver.global_position
		var desired_zone: int = giver.zone_id
		var quest: Dictionary = {}
		for tick in range(2400):
			await process_frame
			quest = world._progress.get("chapter_quests", {}).get(q.quest_id, {})
			var state: int = int(quest.get("state", 0))
			if state == 2:
				break
			if state == 0:
				desired = giver.global_position
				desired_zone = giver.zone_id
				if world._local_player.server_zone_id == desired_zone and world._local_player.server_position.distance_to(desired) <= 2.5:
					world._chapter_accept.rpc_id(1,q.quest_id)
			elif target != null:
				desired = target.global_position
				desired_zone = target.zone_id
				if world._local_player.server_zone_id == desired_zone and world._local_player.server_position.distance_to(desired) <= 2.5:
					var idx: int = world.targets.find(target)
					world._request_auto.rpc_id(1,true,idx)
			else:
				for npc in world.npcs.get_children():
					if npc.npc_id == q.objective_npc_id:
						desired = npc.global_position
						desired_zone = npc.zone_id
						break
				if world._local_player.server_zone_id == desired_zone and world._local_player.server_position.distance_to(desired) <= 2.5:
					world._request_npc.rpc_id(1,q.objective_npc_id)
			if tick == 2399:
				push_error("STAGE843 quest timeout "+q.quest_id+" state="+str(state)+" zone="+str(world._local_player.server_zone_id))
				quit(1)
				return
		completed += 1
		print("STAGE843_NETWORK_QUEST ",completed,"/11 ",q.quest_id)
	var state: Dictionary = world._progress
	if completed != 11 or int(state.get("chapter_quests", {}).get("bell_trial", {}).get("state", 0)) != 2 or int(state.get("experience",0)) < 500:
		push_error("STAGE843 progression incomplete")
		quit(1)
		return
	print("STAGE843_CLIENT=PASS story_quests=11 xp=",state.get("experience",0)," inventory=",state.get("inventory",[]).size())
	quit(0)
