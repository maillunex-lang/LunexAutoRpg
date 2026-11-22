class_name LunexProgressStore
extends RefCounted

enum Quest { AVAILABLE, ACTIVE, COMPLETE, LOCKED }

var _db: Object

func open(path: String) -> bool:
	if not ClassDB.class_exists("SQLite"):
		GDExtensionManager.load_extension("res://addons/godot-sqlite/gdsqlite.gdextension")
	if not ClassDB.class_exists("SQLite"):
		push_error("Server requires the Godot SQLite extension.")
		return false
	_db = ClassDB.instantiate("SQLite")
	_db.path = path
	return (
		_db.open_db()
		and _db.query("PRAGMA synchronous=FULL")
		and _db.query("CREATE TABLE IF NOT EXISTS profiles (id TEXT PRIMARY KEY, quest INTEGER NOT NULL DEFAULT 0, experience INTEGER NOT NULL DEFAULT 0, equipped TEXT NOT NULL DEFAULT '')")
		and _db.query("CREATE TABLE IF NOT EXISTS training_rewards (profile TEXT PRIMARY KEY, item TEXT NOT NULL)")
		and _db.query("CREATE TABLE IF NOT EXISTS quest_progress (profile TEXT NOT NULL, quest_id TEXT NOT NULL, state INTEGER NOT NULL, item TEXT NOT NULL DEFAULT '', equipped TEXT NOT NULL DEFAULT '', PRIMARY KEY (profile, quest_id))")
		and _db.query("INSERT OR IGNORE INTO quest_progress SELECT p.id, 'training', p.quest, COALESCE(r.item, ''), p.equipped FROM profiles p LEFT JOIN training_rewards r ON r.profile = p.id WHERE p.quest > 0 OR r.item IS NOT NULL")
	)

func load_profile(profile: String) -> Dictionary:
	if not _db.query_with_bindings("INSERT OR IGNORE INTO profiles (id) VALUES (?)", [profile]):
		return {}
	return read_profile(profile)

func read_profile(profile: String) -> Dictionary:
	if not _db.query_with_bindings("SELECT experience FROM profiles WHERE id = ?", [profile]) or _db.query_result.is_empty():
		return {}
	var experience: int = _db.query_result[0].experience
	if not _db.query_with_bindings("SELECT quest_id, state, item, equipped FROM quest_progress WHERE profile = ?", [profile]):
		return {}
	var quests := {}
	for row: Dictionary in _db.query_result:
		quests[row.quest_id] = {"quest": row.state, "item": row.item, "equipped": row.equipped}
	return {"experience": experience, "quests": quests}

func is_active(profile: String, quest_id: String) -> bool:
	return _db.query_with_bindings(
		"SELECT 1 FROM quest_progress WHERE profile = ? AND quest_id = ? AND state = ?",
		[profile, quest_id, Quest.ACTIVE]) and not _db.query_result.is_empty()

func accept(profile: String, reward: LunexQuestReward) -> bool:
	return _db.query_with_bindings(
		"""INSERT OR IGNORE INTO quest_progress (profile, quest_id, state)
		SELECT id, ?, ? FROM profiles WHERE id = ? AND
		(? = '' OR EXISTS (SELECT 1 FROM quest_progress WHERE profile = ? AND quest_id = ? AND state = ?))""",
		[reward.quest_id, Quest.ACTIVE, profile, reward.prerequisite_id, profile, reward.prerequisite_id, Quest.COMPLETE])

func complete(profile: String, reward: LunexQuestReward) -> bool:
	if not _db.query("BEGIN IMMEDIATE"):
		return false
	var saved: bool = _db.query_with_bindings(
		"UPDATE quest_progress SET state = ?, item = ? WHERE profile = ? AND quest_id = ? AND state = ?",
		[Quest.COMPLETE, reward.item_id, profile, reward.quest_id, Quest.ACTIVE])
	var granted: bool = saved and _db.query("SELECT changes() AS count") and int(_db.query_result[0].count) == 1
	if granted and _db.query_with_bindings("UPDATE profiles SET experience = experience + ? WHERE id = ?", [reward.experience, profile]) and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func equip(profile: String, quest_id: String) -> bool:
	return _db.query_with_bindings(
		"UPDATE quest_progress SET equipped = item WHERE profile = ? AND quest_id = ? AND state = ? AND item <> ''",
		[profile, quest_id, Quest.COMPLETE])
