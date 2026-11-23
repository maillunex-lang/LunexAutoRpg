extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._start_server(PackedStringArray(["--server", "--port=29051", "--database=user://world_visibility_29051.sqlite"]))
	var seeded := {}
	var verified_initial := false
	var verified_separated := false
	var verified_rejoined := false
	var rejoin_tick := -1
	for tick in range(1500):
		await physics_frame
		if world._profiles.size() != 2:
			continue
		var ids: Array = world._profiles.keys()
		ids.sort()
		var a := world.players.get_node_or_null(str(ids[0])) as LunexNetworkPlayer
		var b := world.players.get_node_or_null(str(ids[1])) as LunexNetworkPlayer
		if a == null or b == null:
			continue
		for id in ids:
			if seeded.has(id):
				continue
			var profile: String = world._profiles[id]
			if not world._store._db.query_with_bindings("INSERT OR REPLACE INTO quest_progress (profile, quest_id, state) VALUES (?, ?, ?)", [profile, "gate_watch", LunexProgressStore.Quest.COMPLETE]):
				push_error("VISIBILITY quest seed failed")
				quit(1)
				return
			seeded[id] = true
		var sa := a.get_node("State") as MultiplayerSynchronizer
		var sb := b.get_node("State") as MultiplayerSynchronizer
		if not verified_initial:
			if not sa.get_visibility_for(ids[1]) or not sb.get_visibility_for(ids[0]):
				push_error("VISIBILITY initial peers hidden")
				quit(1)
				return
			verified_initial = true
			# Isolate visibility transition from navigation timing; crossing is already covered by ENet route tests.
			a.global_position.x = 21.2
			world._update_continuous_zone_membership()
		if tick % 300 == 0:
			print("VISIBILITY_TRACE tick=", tick, " ax=", a.global_position.x, " az=", a.global_position.z, " zone=", a.zone_id, " bx=", b.global_position.x)
		if not verified_separated and a.zone_id == 1:
			if sa.get_visibility_for(ids[1]) or sb.get_visibility_for(ids[0]):
				push_error("VISIBILITY peers exposed across zones")
				quit(1)
				return
			verified_separated = true
			a.global_position.x = 20.8
			world._update_continuous_zone_membership()
		if verified_separated and a.zone_id == 0:
			if not sa.get_visibility_for(ids[1]) or not sb.get_visibility_for(ids[0]):
				push_error("VISIBILITY peers not restored")
				quit(1)
				return
			verified_rejoined = true
			rejoin_tick = tick
		if verified_rejoined:
			print("MAIN_WORLD_ENET_VISIBILITY_SERVER=PASS initial=true separated=true rejoined=true")
			quit(0)
			return
	var positions := []
	for child in world.players.get_children():
		positions.append(str(child.name) + ":" + str(child.global_position) + " zone=" + str(child.zone_id))
	push_error("VISIBILITY timeout initial=" + str(verified_initial) + " separated=" + str(verified_separated) + " rejoined=" + str(verified_rejoined) + " positions=" + str(positions))
	quit(1)
