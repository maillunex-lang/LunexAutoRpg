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
		and _db.query("CREATE TABLE IF NOT EXISTS equipment_items (profile TEXT NOT NULL, item_id TEXT NOT NULL, slot TEXT NOT NULL, rarity INTEGER NOT NULL DEFAULT 1, upgrade_level INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(profile, item_id), FOREIGN KEY(profile) REFERENCES profiles(id))")
		and _db.query("CREATE TABLE IF NOT EXISTS equipped_slots (profile TEXT NOT NULL, slot TEXT NOT NULL, item_id TEXT NOT NULL, PRIMARY KEY(profile, slot), FOREIGN KEY(profile) REFERENCES profiles(id))")
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
	if ok and not columns.has("gold"):
		ok = _db.query("ALTER TABLE profiles ADD COLUMN gold INTEGER NOT NULL DEFAULT 0")
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
	if not _db.query_with_bindings("SELECT experience, class_id, class_selected, gold FROM profiles WHERE id = ?", [profile]) or _db.query_result.is_empty():
		return {}
	var experience: int = _db.query_result[0].experience
	var gold: int = _db.query_result[0].gold
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
	var inventory: Array[Dictionary] = []
	if not _db.query_with_bindings("SELECT item_id, slot, rarity, upgrade_level FROM equipment_items WHERE profile = ? ORDER BY item_id", [profile]):
		return {}
	for row: Dictionary in _db.query_result:
		inventory.append(row.duplicate(true))
	var equipped_slots := {}
	if not _db.query_with_bindings("SELECT slot, item_id FROM equipped_slots WHERE profile = ?", [profile]):
		return {}
	for row: Dictionary in _db.query_result:
		equipped_slots[str(row.slot)] = str(row.item_id)
	return {"experience": experience, "gold": gold, "class_id": class_id, "class_selected": class_selected, "quests": quests, "chapter_quests": chapter, "inventory": inventory, "equipped_slots": equipped_slots, "gear_score": gear_score(profile)}

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

func chapter_complete(profile: String, quest_id: String, goal: int, experience: int = 0, item_id: String = "", rarity: int = 1, gold: int = 0) -> bool:
	if goal < 1 or goal > 1000 or rarity < 1 or rarity > 5 or gold < 0 or gold > 100000 or experience < 0 or experience > 100000 or not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings(
		"UPDATE chapter_quests SET state = 2 WHERE profile = ? AND quest_id = ? AND state = 1 AND objective_count >= ?",
		[profile, quest_id, goal])
	var changed: bool = ok and _db.query("SELECT changes() AS n") and int(_db.query_result[0].n) == 1
	if changed and experience >= 0 and experience <= 100000:
		changed = _db.query_with_bindings("UPDATE profiles SET experience = experience + ?, gold = gold + ? WHERE id = ?", [experience, gold, profile])
	if changed and not item_id.is_empty() and item_id.length() <= 64:
		changed = _db.query_with_bindings("INSERT OR IGNORE INTO quest_progress (profile, quest_id, state, item) VALUES (?, ?, ?, ?)", [profile, "chapter:" + quest_id, Quest.COMPLETE, item_id])
		if changed:
			changed = _db.query_with_bindings("INSERT OR IGNORE INTO equipment_items (profile, item_id, slot, rarity) VALUES (?, ?, ?, ?)", [profile, item_id, equipment_slot_for_item(item_id), rarity])
	if changed and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

func is_chapter_active(profile: String, quest_id: String) -> bool:
	return _db.query_with_bindings(
		"SELECT 1 FROM chapter_quests WHERE profile = ? AND quest_id = ? AND state = 1",
		[profile, quest_id]) and not _db.query_result.is_empty()

const EQUIPMENT_SLOTS := ["weapon", "armor", "helmet", "boots", "ring", "amulet"]

static func equipment_slot_for_item(item_id: String) -> String:
	for slot in EQUIPMENT_SLOTS:
		if item_id.ends_with("_" + slot):
			return slot
	if item_id.ends_with("ring"):
		return "ring"
	if item_id.ends_with("relic") or item_id.ends_with("charm") or item_id.ends_with("emblem"):
		return "amulet"
	return "weapon"

func equip_inventory_item(profile: String, item_id: String) -> bool:
	if item_id.is_empty() or item_id.length() > 64 or not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings("SELECT slot FROM equipment_items WHERE profile = ? AND item_id = ?", [profile, item_id])
	if not ok or _db.query_result.size() != 1:
		_db.query("ROLLBACK")
		return false
	var slot: String = str(_db.query_result[0].slot)
	if slot not in EQUIPMENT_SLOTS:
		_db.query("ROLLBACK")
		return false
	ok = _db.query_with_bindings("INSERT INTO equipped_slots (profile, slot, item_id) VALUES (?, ?, ?) ON CONFLICT(profile, slot) DO UPDATE SET item_id = excluded.item_id", [profile, slot, item_id])
	if ok and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false

static func gear_score_for_item(rarity: int, upgrade_level: int) -> int:
	if rarity < 1 or rarity > 5 or upgrade_level < 0 or upgrade_level > 15:
		return 0
	return rarity * 100 + upgrade_level * (15 + rarity * 5)

func gear_score(profile: String) -> int:
	if not _db.query_with_bindings("SELECT i.rarity, i.upgrade_level FROM equipped_slots s JOIN equipment_items i ON i.profile = s.profile AND i.item_id = s.item_id WHERE s.profile = ?", [profile]):
		return 0
	var total := 0
	for row: Dictionary in _db.query_result:
		total += gear_score_for_item(int(row.rarity), int(row.upgrade_level))
	return total

# Server-only atomic gold sink; no chance of item destruction.
func upgrade_inventory_item(profile: String, item_id: String) -> bool:
	if item_id.is_empty() or item_id.length() > 64 or not _db.query("BEGIN IMMEDIATE"):
		return false
	var ok: bool = _db.query_with_bindings("SELECT upgrade_level FROM equipment_items WHERE profile = ? AND item_id = ?", [profile, item_id])
	if not ok or _db.query_result.size() != 1:
		_db.query("ROLLBACK")
		return false
	var level: int = int(_db.query_result[0].upgrade_level)
	if level < 0 or level >= 15:
		_db.query("ROLLBACK")
		return false
	var cost: int = (level + 1) * 50
	ok = _db.query_with_bindings("UPDATE profiles SET gold = gold - ? WHERE id = ? AND gold >= ?", [cost, profile, cost])
	var paid: bool = ok and _db.query("SELECT changes() AS n") and int(_db.query_result[0].n) == 1
	if paid:
		paid = _db.query_with_bindings("UPDATE equipment_items SET upgrade_level = upgrade_level + 1 WHERE profile = ? AND item_id = ? AND upgrade_level = ?", [profile, item_id, level])
	if paid and _db.query("COMMIT"):
		return true
	_db.query("ROLLBACK")
	return false
