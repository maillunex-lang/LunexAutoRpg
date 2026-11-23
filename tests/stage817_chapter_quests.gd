extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene := load("res://game/network/online_world.tscn") as PackedScene
	var world: Node3D = scene.instantiate()
	root.add_child(world)
	await process_frame
	var definitions: Array[LunexChapterQuestDefinition] = world.chapter_quest_definitions
	if definitions.size() != 10:
		push_error("Expected 10 chapter quests")
		quit(1)
		return
	var ids := {}
	var known_npcs := {}
	for npc in world.npcs.get_children():
		known_npcs[npc.npc_id] = true
	for i in range(definitions.size()):
		var q := definitions[i]
		if q.quest_id.is_empty() or ids.has(q.quest_id):
			push_error("Invalid/duplicate quest id")
			quit(1)
			return
		ids[q.quest_id] = true
		if i > 0 and q.prerequisite_id != definitions[i - 1].quest_id:
			push_error("Broken prerequisite chain " + q.quest_id)
			quit(1)
			return
		if not known_npcs.has(q.npc_id) or not known_npcs.has(q.objective_npc_id):
			push_error("Missing quest NPC " + q.quest_id)
			quit(1)
			return
	print("STAGE817_QUEST_DEFINITIONS=10")
	world.queue_free()
	var store := LunexProgressStore.new()
	if not store.open("user://stage817_chapter_validation.sqlite"):
		push_error("SQLite server test database open failed")
		quit(1)
		return
	var profile := "nexus_run4_test_" + str(Time.get_ticks_usec())
	if store.load_profile(profile).is_empty():
		push_error("Profile create failed")
		quit(1)
		return
	if store.chapter_accept(profile, definitions[1].quest_id, definitions[1].prerequisite_id):
		push_error("Prerequisite bypass")
		quit(1)
		return
	for q in definitions:
		if not store.chapter_accept(profile,q.quest_id,q.prerequisite_id):
			push_error("Quest accept failed " + q.quest_id)
			quit(1)
			return
		if not store.chapter_advance(profile,q.quest_id,1,q.objective_goal):
			push_error("Objective failed " + q.quest_id)
			quit(1)
			return
		if not store.chapter_complete(profile,q.quest_id,q.objective_goal):
			push_error("Complete failed " + q.quest_id)
			quit(1)
			return
	var progress: Dictionary = store.read_profile(profile).get("chapter_quests",{})
	if progress.size() != 10:
		push_error("Persistence failed")
		quit(1)
		return
	print("STAGE817_QUEST_PERSISTENCE=10")
	quit()
