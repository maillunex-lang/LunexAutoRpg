extends SceneTree
## Isolate the three outcomes of one telegraphed attack around a real arena obstacle.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := preload("res://game/network/online_world.tscn").instantiate()
	root.add_child(scene)
	scene.watch.position = Vector3(0, 0, -4.9)
	scene.watch.players = scene.players
	var behind_wall := _add_player(scene.players, Vector3(0, 0, -3.1))
	var stays_inside := _add_player(scene.players, Vector3(1.8, 0, -4.9))
	var dodges := _add_player(scene.players, Vector3(-1.8, 0, -4.9))
	await physics_frame
	await physics_frame
	scene.watch.take_hit(1, 2)
	await create_timer(0.25).timeout
	if not scene.watch.telegraph_active:
		push_error("Counterattack did not begin.")
		quit(1)
		return
	dodges.position.x = -3.0
	await create_timer(0.9).timeout
	if behind_wall.health != 100 or dodges.health != 100 or stays_inside.health != 80:
		push_error("Counterattack must hit only players who remain within clear range.")
		quit(1)
		return
	print("PASS: one guard attack respects obstacle, dodge and in-range hit together")
	quit()

func _add_player(parent: Node, at: Vector3) -> LunexNetworkPlayer:
	var player := preload("res://game/network/network_player.tscn").instantiate() as LunexNetworkPlayer
	player.prepare(parent.get_child_count() + 2, at, "Test")
	parent.add_child(player)
	return player
