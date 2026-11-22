class_name LunexProgressStore
extends RefCounted

enum Quest { AVAILABLE, ACTIVE, COMPLETE }

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
	)

func load_profile(profile: String) -> Dictionary:
	if not _db.query_with_bindings("INSERT OR IGNORE INTO profiles (id) VALUES (?)", [profile]):
		return {}
	return read_profile(profile)

func read_profile(profile: String) -> Dictionary:
	var sql := "SELECT p.quest, p.experience, p.equipped, COALESCE(r.item, '') AS item FROM profiles p LEFT JOIN training_rewards r ON r.profile = p.id WHERE p.id = ?"
	if not _db.query_with_bindings(sql, [profile]) or _db.query_result.is_empty():
		return {}
	return _db.query_result[0]

func accept(profile: String) -> bool:
	return _db.query_with_bindings("UPDATE profiles SET quest = ? WHERE id = ? AND quest = ?", [Quest.ACTIVE, profile, Quest.AVAILABLE])

func complete(profile: String, reward: LunexQuestReward) -> bool:
	if not _db.query("BEGIN IMMEDIATE"):
		return false
	var issued: bool = _db.query_with_bindings(
		"INSERT INTO training_rewards (profile, item) SELECT id, ? FROM profiles WHERE id = ? AND quest = ?",
		[reward.item_id, profile, Quest.ACTIVE])
	var saved: bool = issued and _db.query_with_bindings(
		"UPDATE profiles SET quest = ?, experience = experience + ? WHERE id = ? AND quest = ?",
		[Quest.COMPLETE, reward.experience, profile, Quest.ACTIVE])
	if saved and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func equip(profile: String) -> bool:
	return _db.query_with_bindings(
		"UPDATE profiles SET equipped = (SELECT item FROM training_rewards WHERE profile = ?) WHERE id = ? AND EXISTS (SELECT 1 FROM training_rewards WHERE profile = ?)",
		[profile, profile, profile])
