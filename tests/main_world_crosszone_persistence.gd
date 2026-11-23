extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var path := "user://crosszone_persistence_" + str(Time.get_ticks_usec()) + ".sqlite"
	var profile := "crosszone_persistence"
	var store := LunexProgressStore.new()
	if not store.open(path) or store.load_profile(profile).is_empty():
		push_error("PERSIST open/profile failed")
		quit(1)
		return
	if not store._db.query_with_bindings("INSERT INTO quest_progress (profile, quest_id, state) VALUES (?, ?, ?)", [profile, "gate_watch", LunexProgressStore.Quest.COMPLETE]):
		push_error("PERSIST gate completion failed")
		quit(1)
		return
	if not store.chapter_accept(profile, "first_steps") or not store.chapter_advance(profile, "first_steps", 1, 1) or not store.chapter_complete(profile, "first_steps", 1, 25, "", 1, 40):
		push_error("PERSIST chapter progress failed")
		quit(1)
		return
	store._db.close_db()
	store = null
	var reopened := LunexProgressStore.new()
	if not reopened.open(path):
		push_error("PERSIST reopen failed")
		quit(1)
		return
	var state := reopened.read_profile(profile)
	if int(state.get("quests", {}).get("gate_watch", {}).get("quest", -1)) != LunexProgressStore.Quest.COMPLETE or int(state.get("chapter_quests", {}).get("first_steps", {}).get("state", -1)) != LunexProgressStore.Quest.COMPLETE or int(state.get("gold", -1)) != 40 or int(state.get("experience", -1)) != 25:
		push_error("PERSIST state mismatch: " + str(state))
		quit(1)
		return
	print("MAIN_WORLD_CROSSZONE_PERSISTENCE=PASS reopen=true gate_quest=true chapter_quest=true experience=25 gold=40")
	reopened._db.close_db()
	quit(0)
