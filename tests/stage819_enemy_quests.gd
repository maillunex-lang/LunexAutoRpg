extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var found := 0
	for q in world.chapter_quest_definitions:
		if q.objective_enemy_id.is_empty():
			continue
		var target_exists := false
		for enemy in world.targets:
			if enemy.target_id == q.objective_enemy_id:
				target_exists = true
		if not target_exists or q.objective_goal != 1:
			push_error("Broken enemy objective")
			quit(1)
			return
		found += 1
	if found != 3:
		push_error("Expected three combat quests")
		quit(1)
		return
	print("STAGE819_ENEMY_QUEST_TOTAL=3")
	world.queue_free()
	quit()
