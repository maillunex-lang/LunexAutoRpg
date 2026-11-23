extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var checked := 0
	for class_id in ["warrior", "mage", "priest", "bard"]:
		if not world.CLASS_SKILLS.has(class_id) or world.CLASS_SKILLS[class_id].size() != 2:
			push_error("Class skill wiring broken: " + class_id)
			quit(1)
			return
		checked += 1
	for enemy_name in ["AshWanderer", "MistHunter"]:
		var enemy := world.get_node(enemy_name) as LunexGateWatch
		if enemy == null or enemy.counter_damage <= 0 or enemy.counter_radius <= 0.0:
			push_error("Enemy FSM telegraph absent " + enemy_name)
			quit(1)
			return
		checked += 1
	if world.targets.size() != 5:
		push_error("Server target array mismatch")
		quit(1)
		return
	checked += 1
	print("STAGE817_COMBAT_TOTAL=",checked)
	world.queue_free()
	quit()
