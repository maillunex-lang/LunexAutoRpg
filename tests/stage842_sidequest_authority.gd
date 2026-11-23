extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(0) != OK:
		push_error("No isolated server")
		quit(1)
		return
	world.multiplayer.multiplayer_peer = peer
	if world.side_quest_definitions.size() != 3:
		push_error("Three authored side quests expected")
		quit(1)
		return
	var ids := {}
	for side in world.side_quest_definitions:
		if side == null or side.story_intro.is_empty() or side.quest_id in ids or side.objective_enemy_id.is_empty():
			push_error("Invalid optional quest definition")
			quit(1)
			return
		ids[side.quest_id] = true
		if world._chapter_definition(side.quest_id) != side:
			push_error("Cannot resolve side quest")
			quit(1)
			return
	var store: LunexProgressStore = world._store
	if not store.open("user://content842_sidequests.sqlite"):
		push_error("DB init")
		quit(1)
		return
	var profile := "sidequest_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	var side: LunexChapterQuestDefinition = world.side_quest_definitions[0]
	if world._chapter_available(profile, side):
		push_error("Side quest must be locked until prerequisite")
		quit(1)
		return
	var prior: LunexChapterQuestDefinition = world._chapter_definition(side.prerequisite_id)
	if prior == null or not store.chapter_accept(profile, prior.quest_id, "") or not store.chapter_advance(profile, prior.quest_id, 1, prior.objective_goal) or not store.chapter_complete(profile, prior.quest_id, prior.objective_goal):
		push_error("Prerequisite completion failed")
		quit(1)
		return
	if not world._chapter_available(profile, side):
		push_error("Side quest did not unlock")
		quit(1)
		return
	if not store.chapter_accept(profile, side.quest_id, side.prerequisite_id):
		push_error("Cannot accept side quest")
		quit(1)
		return
	if store.chapter_accept(profile, side.quest_id, side.prerequisite_id):
		push_error("Duplicate side quest accepted")
		quit(1)
		return
	if not store.chapter_advance(profile, side.quest_id, 1, 1) or not store.chapter_complete(profile, side.quest_id, 1, side.reward_experience, side.reward_item_id, side.reward_rarity, side.reward_gold):
		push_error("Cannot complete side quest")
		quit(1)
		return
	var state: Dictionary = store.read_profile(profile)
	if int(state.get("chapter_quests", {}).get(side.quest_id, {}).get("state",0)) != 2 or int(state.get("gold",0)) != side.reward_gold or int(state.get("experience",0)) != side.reward_experience:
		push_error("Wrong side quest reward")
		quit(1)
		return
	if store.chapter_complete(profile, side.quest_id, 1, side.reward_experience, side.reward_item_id, side.reward_rarity, side.reward_gold):
		push_error("Duplicate side quest reward")
		quit(1)
		return
	print("STAGE842_SIDE_QUESTS=PASS definitions=",ids.size()," prerequisites reward_once")
	quit(0)
