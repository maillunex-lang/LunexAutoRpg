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
	if not _db.open_db() or not _db.query("PRAGMA synchronous=FULL"):
		return false
	if not _db.query("CREATE TABLE IF NOT EXISTS profiles (id TEXT PRIMARY KEY, quest INTEGER NOT NULL DEFAULT 0, experience INTEGER NOT NULL DEFAULT 0, equipped TEXT NOT NULL DEFAULT '')"):
		return false
	if not _migrate_classes():
		return false
	return (
		_db.query("CREATE TABLE IF NOT EXISTS training_rewards (profile TEXT PRIMARY KEY, item TEXT NOT NULL)")
		and _db.query("CREATE TABLE IF NOT EXISTS quest_progress (profile TEXT NOT NULL, quest_id TEXT NOT NULL, state INTEGER NOT NULL, item TEXT NOT NULL DEFAULT '', equipped TEXT NOT NULL DEFAULT '', PRIMARY KEY (profile, quest_id))")
		and _db.query("CREATE TABLE IF NOT EXISTS chapter_quests (profile TEXT NOT NULL, quest_id TEXT NOT NULL, state INTEGER NOT NULL DEFAULT 0, objective_count INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(profile, quest_id), FOREIGN KEY(profile) REFERENCES profiles(id))")
		and _db.query("INSERT OR IGNORE INTO quest_progress SELECT p.id, 'training', p.quest, COALESCE(r.item, ''), p.equipped FROM profiles p LEFT JOIN training_rewards r ON r.profile = p.id WHERE p.quest > 0 OR r.item IS NOT NULL")
	)

# Migration is atomic and repeatable. Every pre-existing character is assigned warrior.
func _migrate_classes() -> bool:
	if not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query("PRAGMA table_info(profiles)")
	var columns := {}
	if ok:
		for row: Dictionary in _db.query_result:
			columns[str(row.name)] = true
		for required in ["id", "quest", "experience", "equipped"]:
			if not columns.has(required):
				ok = false
				break
	if ok and not columns.has("class_id"):
		ok = _db.query("ALTER TABLE profiles ADD COLUMN class_id TEXT NOT NULL DEFAULT 'warrior'")
	if ok and not columns.has("class_selected"):
		ok = _db.query("ALTER TABLE profiles ADD COLUMN class_selected INTEGER NOT NULL DEFAULT 1")
	if ok:
		ok = _db.query("UPDATE profiles SET class_id = 'warrior' WHERE class_id IS NULL OR class_id = ''")
	if ok and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

# Whitelist enforced server-side. Actual class selection belongs to 7.7.2.
func is_valid_class_id(class_id: String) -> bool:
	return class_id in ["warrior", "mage", "priest", "bard"]

func assign_class(profile: String, class_id: String) -> bool:
	if not is_valid_class_id(class_id) or not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings("UPDATE profiles SET class_id = ?, class_selected = 1 WHERE id = ? AND class_selected = 0", [class_id, profile])
	var changed: bool = ok and _db.query("SELECT changes() AS n") and int(_db.query_result[0].n) == 1
	if changed and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func load_profile(profile: String) -> Dictionary:
	if not _db.query_with_bindings("INSERT OR IGNORE INTO profiles (id, class_selected) VALUES (?, 0)", [profile]):
		return {}
	return read_profile(profile)

func read_profile(profile: String) -> Dictionary:
	if not _db.query_with_bindings("SELECT experience, class_id, class_selected FROM profiles WHERE id = ?", [profile]) or _db.query_result.is_empty():
		return {}
	var experience: int = _db.query_result[0].experience
	var class_id: String = str(_db.query_result[0].class_id)
	var class_selected: bool = int(_db.query_result[0].class_selected) == 1
	if not _db.query_with_bindings("SELECT quest_id, state, item, equipped FROM quest_progress WHERE profile = ?", [profile]):
		return {}
	var quests := {}
	for row: Dictionary in _db.query_result:
		quests[row.quest_id] = {"quest": row.state, "item": row.item, "equipped": row.equipped}
	if not _db.query_with_bindings("SELECT quest_id, state, objective_count FROM chapter_quests WHERE profile = ?", [profile]):
		return {}
	var chapter := {}
	for row: Dictionary in _db.query_result:
		chapter[row.quest_id] = {"state": row.state, "count": row.objective_count}
	return {"experience": experience, "class_id": class_id, "class_selected": class_selected, "quests": quests, "chapter_quests": chapter}

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

# Separate chapter quest state. No rewards or content are activated in 7.6.3.
# All transitions are guarded by a transaction and the current state.
func chapter_accept(profile: String, quest_id: String, prerequisite_id: String = "") -> bool:
	if not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings(
		"""INSERT OR IGNORE INTO chapter_quests (profile, quest_id, state)
		SELECT id, ?, 1 FROM profiles WHERE id = ? AND
		(? = '' OR EXISTS (SELECT 1 FROM chapter_quests WHERE profile = ? AND quest_id = ? AND state = 2))""",
		[quest_id, profile, prerequisite_id, profile, prerequisite_id])
	var changed: bool = ok and _db.query("SELECT changes() AS n") and int(_db.query_result[0].n) == 1
	if changed and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func chapter_advance(profile: String, quest_id: String, amount: int, goal: int) -> bool:
	if amount != 1 or goal < 1 or goal > 1000:
		return false
	if not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings(
		"UPDATE chapter_quests SET objective_count = MIN(objective_count + ?, ?) WHERE profile = ? AND quest_id = ? AND state = 1 AND objective_count < ?",
		[amount, goal, profile, quest_id, goal])
	var changed: bool = ok and _db.query("SELECT changes() AS n") and int(_db.query_result[0].n) == 1
	if changed and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func chapter_complete(profile: String, quest_id: String, goal: int) -> bool:
	if goal < 1 or goal > 1000 or not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings(
		"UPDATE chapter_quests SET state = 2 WHERE profile = ? AND quest_id = ? AND state = 1 AND objective_count >= ?",
		[profile, quest_id, goal])
	var changed: bool = ok and _db.query("SELECT changes() AS n") and int(_db.query_result[0].n) == 1
	if changed and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func is_chapter_active(profile: String, quest_id: String) -> bool:
	return _db.query_with_bindings(
		"SELECT 1 FROM chapter_quests WHERE profile = ? AND quest_id = ? AND state = 1",
		[profile, quest_id]) and not _db.query_result.is_empty()
