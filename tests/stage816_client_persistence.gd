extends SceneTree

var checks := 0
func verify(condition: bool, label: String) -> bool:
	if not condition:
		push_error("FAIL: " + label)
		quit(1)
		return false
	checks += 1
	print("PASS: ", label)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://game/network/online_world.tscn") as PackedScene
	if not verify(scene != null, "Client world loads"): return
	var client := scene.instantiate()
	root.add_child(client)
	await process_frame
	if not verify(client._store._db == null, "Client does not open SQLite"): return
	if not verify(not ClassDB.class_exists("SQLite"), "Client does not load SQLite extension"): return
	if not verify(client.hud_editor != null, "Client native HUD editor available"): return
	if not verify(client.screen != null, "Client connection UI available"): return
	client.queue_free()
	print("STAGE816_CLIENT_TOTAL=", checks)
	quit()
