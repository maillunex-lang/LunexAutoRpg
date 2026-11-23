extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=29052", "--database=user://world_reconnect_29052.sqlite"]))
	var first_peer := -1
	var first_profile := ""
	var disconnected := false
	for tick in range(1700):
		await physics_frame
		if first_peer < 0 and not world._profiles.is_empty():
			first_peer = int(world._profiles.keys()[0])
			first_profile = str(world._profiles[first_peer])
			if not world._store._db.query_with_bindings("INSERT OR REPLACE INTO quest_progress (profile, quest_id, state) VALUES (?, ?, ?)", [first_profile, "gate_watch", LunexProgressStore.Quest.COMPLETE]):
				push_error("RECONNECT seed gate failed")
				quit(1)
				return
			if not world._store.chapter_accept(first_profile, "first_steps") or not world._store.chapter_advance(first_profile, "first_steps", 1, 1) or not world._store.chapter_complete(first_profile, "first_steps", 1, 25, "", 1, 40):
				push_error("RECONNECT seed quest failed")
				quit(1)
				return
			world._publish_progress(first_peer, first_profile)
		if first_peer >= 0 and not world._profiles.has(first_peer):
			disconnected = true
		if disconnected and not world._profiles.is_empty():
			var peer_id: int = int(world._profiles.keys()[0])
			var profile: String = world._profiles[peer_id]
			var state: Dictionary = world._store.read_profile(profile)
			if profile != first_profile or int(state.get("gold", -1)) != 40 or int(state.get("experience", -1)) != 25 or int(state.get("quests", {}).get("gate_watch", {}).get("quest", -1)) != LunexProgressStore.Quest.COMPLETE or int(state.get("chapter_quests", {}).get("first_steps", {}).get("state", -1)) != LunexProgressStore.Quest.COMPLETE:
				push_error("RECONNECT persisted state mismatch")
				quit(1)
				return
			print("MAIN_WORLD_ENET_RECONNECT_SERVER=PASS same_profile=true gate=true chapter=true xp=25 gold=40")
			for hold in range(100):
				await physics_frame
			quit(0)
			return
	push_error("RECONNECT timeout first=" + str(first_peer) + " disconnected=" + str(disconnected))
	quit(1)
