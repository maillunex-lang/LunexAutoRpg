extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var names := ["NPCs/Mara", "NPCs/Erin", "AshWanderer", "MistHunter"]
	for path in names:
		if not world.has_node(path):
			push_error("Missing world content " + path)
			quit(1)
			return
	if world.targets.size() != 8:
		push_error("Enemy targets not wired")
		quit(1)
		return
	if world.npcs.get_child_count() != 8:
		push_error("NPCs not editable scene instances")
		quit(1)
		return
	print("STAGE817_WORLD_TOTAL=6")
	world.queue_free()
	quit()
