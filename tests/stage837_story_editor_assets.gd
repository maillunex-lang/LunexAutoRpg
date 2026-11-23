extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var dialogs: LunexDialogueWindow = world.dialogue_window
	if dialogs.dialogue_entries.size() != 8:
		push_error("Expected eight editor-authored dialogs")
		quit(1)
		return
	var ids := {}
	for item in dialogs.dialogue_entries:
		if item == null or not item.is_valid_definition() or ids.has(item.npc_id):
			push_error("Invalid/duplicate editor-authored NPC dialogue")
			quit(1)
			return
		ids[item.npc_id] = true
		var resource: DialogueResource = get_root().get_node("DialogueManager").create_resource_from_text(item.dialogue_text)
		if resource == null:
			push_error("Dialogue parser rejected NPC " + item.npc_id)
			quit(1)
			return
	if world.chapter_quest_definitions.size() != 11:
		push_error("Main chapter has wrong quest count")
		quit(1)
		return
	var old_id := ""
	for definition in world.chapter_quest_definitions:
		if definition.story_intro.is_empty() or definition.prerequisite_id != old_id:
			push_error("Broken chapter quest intro or order " + definition.quest_id)
			quit(1)
			return
		old_id = definition.quest_id
	var state := {"experience": 0, "gold":0,"gear_score": 0, "class_id":"warrior", "class_selected": true, "quests": {}, "chapter_quests": {}, "equipped_slots": {}}
	world.progress_hud.show_state(state, world.quest_rewards, 50, world.chapter_quest_definitions)
	var chapter_button: Button = world.progress_hud.get_node("Panel/Margin/Fields/ChapterRoute")
	var detail: Label = world.progress_hud.get_node("Panel/Margin/Fields/ChapterDetail")
	if chapter_button.disabled or chapter_button.text != "К персонажу за заданием" or not detail.text.contains(world.chapter_quest_definitions[0].story_intro):
		push_error("The next quest is not accessible from journal")
		quit(1)
		return
	var actions: PackedScene = load("res://game/dialogue/quest_action_button.tscn")
	if actions == null:
		push_error("Missing native editable quest action button")
		quit(1)
		return
	print("STAGE837_STORY_EDITOR=PASS dialogues=", ids.size(), " main_quests=", world.chapter_quest_definitions.size(), " next_quest_route=enabled")
	quit(0)
