extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=28997", "--database=user://content847_reconnect.sqlite"]))
	if not world.multiplayer.is_server():
		push_error("STAGE847 server start failed")
		quit(1)
		return
	var seeded := false
	var disconnected := false
	for tick in range(5000):
		await process_frame
		if seeded and world._profiles.is_empty():
			disconnected = true
		for peer_id in world._profiles.keys():
			var profile: String = world._profiles[peer_id]
			if not seeded:
				if not world._store.chapter_accept(profile,"stage847_gear") or not world._store.chapter_advance(profile,"stage847_gear",1,1) or not world._store.chapter_complete(profile,"stage847_gear",1,25,"stage847_weapon",3,150):
					push_error("STAGE847 seed failed")
					quit(1)
					return
				seeded = true
				world._publish_progress(peer_id,profile)
			var state: Dictionary = world._store.read_profile(profile)
			if disconnected and int(state.get("gold",0)) == 100 and int(state.get("gear_score",0)) == 330 and state.get("equipped_slots",{}).get("weapon","") == "stage847_weapon" and int(state.get("inventory",[])[0].get("upgrade_level",0)) == 1:
				print("STAGE847_SERVER=PASS persisted_after_reconnect")
				quit(0)
				return
	push_error("STAGE847 server timeout seeded="+str(seeded)+" disconnected="+str(disconnected))
	quit(1)
