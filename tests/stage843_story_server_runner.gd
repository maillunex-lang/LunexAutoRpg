extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=28995", "--database=user://content843_story.sqlite"]))
	if not world.multiplayer.is_server():
		push_error("STAGE843 isolated ENet server failed to start")
		quit(1)
		return
	var steps := 0
	for tick in range(18000):
		await physics_frame
		for child in world.players.get_children():
			var player := child as LunexNetworkPlayer
			if player == null or not world._profiles.has(player.peer_id):
				continue
			player.max_health = 1200
			player.health = maxi(player.health, 1000)
			player.attack_damage = 65
			var state: Dictionary = world._store.read_profile(world._profiles[player.peer_id])
			var pending: LunexChapterQuestDefinition
			var active := false
			for quest in world.chapter_quest_definitions:
				var status: int = int(state.get("chapter_quests", {}).get(quest.quest_id, {}).get("state", 0))
				if status == 2:
					continue
				pending = quest
				active = status == 1
				break
			if pending == null:
				var verified := 0
				for quest in world.chapter_quest_definitions:
					if int(state.get("chapter_quests", {}).get(quest.quest_id, {}).get("state", 0)) == LunexProgressStore.Quest.COMPLETE:
						verified += 1
				if verified != 11 or int(state.get("experience",0)) < 500:
					push_error("STAGE843 story ended with incomplete persisted progress")
					quit(1)
					return
				print("STAGE843_STORY_SERVER=PASS quests=",verified," experience=",state.get("experience",0)," saved_inventory=",state.get("inventory",[]).size())
				quit(0)
				return
			var pos: Vector3
			var zone: int
			if not active:
				var giver: LunexNpcActor = world._chapter_giver(pending)
				pos = giver.global_position
				zone = giver.zone_id
			elif not pending.objective_enemy_id.is_empty():
				var enemy: LunexTrainingEnemy
				for target in world.targets:
					if target.target_id == pending.objective_enemy_id:
						enemy = target
						break
				if enemy == null:
					push_error("STAGE843 quest target missing "+pending.quest_id)
					quit(1)
					return
				pos = enemy.global_position + Vector3(0.7,0.0,0.7)
				zone = enemy.zone_id
			else:
				for npc in world.npcs.get_children():
					if npc.npc_id == pending.objective_npc_id:
						pos = npc.global_position
						zone = npc.zone_id
						break
			if player.zone_id != zone:
				player.enter_zone(zone,pos)
				world._arrive.rpc_id(player.peer_id,zone,pos)
				world._update_zone_visibility(player)
			elif player.global_position.distance_to(pos) > 1.0:
				player.global_position = pos
				player.server_position = pos
			if tick % 120 == 0:
				steps = maxi(steps, world.chapter_quest_definitions.find(pending))
	push_error("STAGE843 story server runner timeout")
	quit(1)
