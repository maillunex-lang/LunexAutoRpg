extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=28996", "--database=user://content846_gear.sqlite"]))
	if not world.multiplayer.is_server():
		push_error("STAGE846 server unavailable")
		quit(1)
		return
	var seeded := false
	for tick in range(3600):
		await process_frame
		for peer_id in world._profiles.keys():
			var profile: String = world._profiles[peer_id]
			if not seeded:
				if not world._store.chapter_accept(profile, "stage846_gear") or not world._store.chapter_advance(profile, "stage846_gear", 1, 1) or not world._store.chapter_complete(profile, "stage846_gear", 1, 20, "stage846_weapon", 3, 150):
					push_error("STAGE846 server reward seed failed")
					quit(1)
					return
				world._publish_progress(peer_id,profile)
				seeded = true
			var state: Dictionary = world._store.read_profile(profile)
			if int(state.get("gold",0)) == 100 and int(state.get("gear_score",0)) == 330 and state.get("equipped_slots",{}).get("weapon","") == "stage846_weapon":
				print("STAGE846_SERVER=PASS server_authoritative_equip_upgrade_gold_persist")
				quit(0)
				return
	push_error("STAGE846 server timeout")
	quit(1)
