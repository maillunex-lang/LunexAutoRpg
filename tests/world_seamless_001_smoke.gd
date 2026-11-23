extends SceneTree

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var scene := load("res://demo/seamless/seamless_demo.tscn") as PackedScene
	assert(scene != null, "demo scene missing")
	var world := scene.instantiate()
	root.add_child(world)
	await process_frame
	var player: CharacterBody3D = world.get_node("Player")
	var chunks: SeamlessChunkStreamer = world.get_node("Chunks")
	assert(chunks.loaded_count() == 2, "two adjacent chunks should preload")
	assert(chunks.loaded_indices().has(0) and chunks.loaded_indices().has(1), "both zones visible")
	assert(chunks.get_node_or_null("StartMeadow") != null, "start scene not instanced")
	assert(chunks.get_node_or_null("AshGroveEdge") != null, "grove scene not instanced")
	var start_id := player.get_instance_id()
	for i in range(180):
		world._physics_process(1.0 / 30.0)
	assert(player.global_position.z < -23.0, "player did not cross boundary")
	assert(player.get_instance_id() == start_id, "player was replaced on transition")
	assert(not world.auto_travel, "auto navigation did not finish")
	assert(chunks.loaded_count() <= 2, "chunk budget exceeded")
	assert(chunks._index_for_position(player.global_position) == 1, "wrong destination zone")
	chunks.preload_radius = 0
	chunks.update_streaming()
	assert(chunks.loaded_count() == 1 and chunks.loaded_indices().has(1), "far chunk was not unloaded")
	player.global_position = Vector3(0, 0.5, 0)
	chunks.update_streaming()
	assert(chunks.loaded_count() == 1 and chunks.loaded_indices().has(0), "start chunk was not restored")
	print("WORLD_SEAMLESS_001=PASS native_scenes=2 continuous_player=true no_scene_change=true autopilot=true chunks_bounded=true unload_reload=true")
	quit(0)
