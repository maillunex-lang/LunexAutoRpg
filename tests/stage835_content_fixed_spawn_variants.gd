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
	var target: LunexTrainingEnemy = world.ash_wanderer
	var ordinary: int = target.definition.max_health
	target.respawn_delay = 0.1
	target.definition.elite_spawn_chance = 1.0
	target.take_hit(10000, 2)
	for i in range(24):
		await physics_frame
	if not target.is_elite or target.health != ceili(ordinary * target.definition.elite_health_multiplier) or not target.target_name.contains("Элита"):
		push_error("Elite spawn variant was not authoritatively selected")
		quit(1)
		return
	print("STAGE835_ELITE=PASS normal=%d elite=%d" % [ordinary, target.health])
	target.definition.elite_spawn_chance = 0.0
	target.take_hit(10000, 2)
	for i in range(24):
		await physics_frame
	if target.is_elite or target.health != ordinary or target.target_name.contains("Элита"):
		push_error("Normal spawn restoration failed")
		quit(1)
		return
	print("STAGE835_NORMAL=PASS health=%d" % target.health)
	quit(0)
