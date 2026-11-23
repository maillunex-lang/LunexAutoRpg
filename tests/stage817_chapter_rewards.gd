extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var quests: Array[LunexChapterQuestDefinition] = world.chapter_quest_definitions
	var store := LunexProgressStore.new()
	if not store.open("user://stage817_rewards_validation.sqlite"):
		quit(1)
		return
	var profile := "rewards_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	var expected_exp := 0
	for q in quests:
		if not store.chapter_accept(profile,q.quest_id,q.prerequisite_id):
			push_error("Accept failed")
			quit(1)
			return
		if not store.chapter_advance(profile,q.quest_id,1,q.objective_goal):
			push_error("Objective failed")
			quit(1)
			return
		if not store.chapter_complete(profile,q.quest_id,q.objective_goal,q.reward_experience,q.reward_item_id):
			push_error("Reward failed")
			quit(1)
			return
		expected_exp += q.reward_experience
		if store.chapter_complete(profile,q.quest_id,q.objective_goal,q.reward_experience,q.reward_item_id):
			push_error("Duplicate XP grant")
			quit(1)
			return
	var state := store.read_profile(profile)
	if state.experience != expected_exp:
		push_error("XP persistence mismatch")
		quit(1)
		return
	for q in [quests[4],quests[9]]:
		if state.quests.get("chapter:" + q.quest_id,{}).get("item","") != q.reward_item_id:
			push_error("Item missing")
			quit(1)
			return
		if not store.equip(profile,"chapter:" + q.quest_id):
			push_error("Equip failed")
			quit(1)
			return
	print("STAGE817_REWARDS_TOTAL=",quests.size() + 5)
	world.queue_free()
	quit()
