extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(0) != OK:
		push_error("STAGE840 could not start isolated server")
		quit(1)
		return
	world.multiplayer.multiplayer_peer = peer
	var db := "user://content840_story_multizone.sqlite"
	if not world._store.open(db):
		push_error("STAGE840 SQLite failed")
		quit(1)
		return
	var profile := "storyroute_" + str(Time.get_ticks_usec())
	world._store.load_profile(profile)
	world._profiles[2] = profile
	world._spawn_slots[2] = 0
	var giver: LunexNpcActor = world._chapter_giver(world._chapter_definition("bell_trial"))
	if giver == null or giver.zone_id != 4:
		push_error("STAGE840 missing final quest giver")
		quit(1)
		return
	# Preconditions for bell_trial are fulfilled by a real authorized SQLite quest sequence.
	for definition in world.chapter_quest_definitions:
		if definition.quest_id == "bell_trial":
			break
		if not world._store.chapter_accept(profile, definition.quest_id, definition.prerequisite_id):
			push_error("STAGE840 failed to accept " + definition.quest_id)
			quit(1)
			return
		if not world._store.chapter_advance(profile, definition.quest_id, 1, definition.objective_goal):
			push_error("STAGE840 failed to advance " + definition.quest_id)
			quit(1)
			return
		if not world._store.chapter_complete(profile, definition.quest_id, definition.objective_goal):
			push_error("STAGE840 failed to complete " + definition.quest_id)
			quit(1)
			return
	var player: LunexNetworkPlayer = world._spawn_player([2, world.gates[1].global_position, "StoryRoute", "warrior"])
	world.players.add_child(player)
	player.enter_zone(1, world.gates[1].global_position)
	if not world._chapter_available(profile, world._chapter_definition("bell_trial")):
		push_error("STAGE840 final giver quest incorrectly locked")
		quit(1)
		return
	# Seamless-world contract: no zone mutation in quest route planning.
	player.set_quest_destination(giver.global_position)
	world._quest_routes[2] = "giver:bell_trial"
	var before_position := player.global_position
	world._advance_quest_routes()
	if player.zone_id != 1 or player.global_position.distance_to(before_position) > 0.001:
		push_error("STAGE840 route planner teleported player")
		quit(1)
		return
	if not world._quest_routes.has(2) or not player.quest_auto_enabled or player.quest_destination.distance_to(giver.global_position) > 0.1:
		push_error("STAGE840 did not retain full-world destination")
		quit(1)
		return
	print("STAGE840_GIVER_ZONES=PASS no_teleport=true route_1_to_4=true final_npc_destination=true")
	quit(0)
