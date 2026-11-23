extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var cinematic: LunexStoryCinematic = world.story_cinematic
	if cinematic == null or cinematic.visible:
		push_error("Missing hidden native editable cinematic")
		quit(1)
		return
	cinematic.begin()
	if not cinematic.visible or not cinematic.story_text.text.contains("Колокол"):
		push_error("Cinematic did not start correctly")
		quit(1)
		return
	var finished := [0]
	cinematic.finished.connect(func() -> void: finished[0] += 1)
	cinematic.skip_button.pressed.emit()
	if cinematic.visible or finished[0] != 1:
		push_error("Cinematic skip failed")
		quit(1)
		return
	var state := {"chapter_quests": {"bell_trial": {"state": 2}}, "experience": 0, "gold": 0, "gear_score":0, "quests":{}, "equipped_slots": {}, "class_id":"warrior", "class_selected":true}
	world._progress = {"chapter_quests": {"bell_trial": {"state": 1}}}
	world._receive_progress(state)
	if not cinematic.visible:
		push_error("Finale completion did not activate cinematic")
		quit(1)
		return
	world._progress = {}
	world.story_cinematic.hide()
	world._story_finale_seen = false
	world._receive_progress(state)
	if cinematic.visible:
		push_error("Finale scene replayed during first progress snapshot/reconnect")
		quit(1)
		return
	print("STAGE841_FINALE=PASS native_scene skip_on_click start_on_final_quest no_reconnect_replay")
	quit(0)
