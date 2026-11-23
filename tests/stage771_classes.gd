extends SceneTree

var count := 0
func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("FAIL: " + message)
		quit(1)
		return false
	count += 1
	print("PASS: ", message)
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		quit(2)
		return
	var old_path: String = args[0]
	var new_path: String = args[1]
	var broken_path: String = args[2]
	var store := LunexProgressStore.new()
	if not check(store.open(old_path), "legacy database migrated"): return
	var a := store.read_profile("old_a")
	if not check(a.class_id == "warrior" and a.class_selected and a.experience == 77, "legacy profile auto warrior, experience intact"): return
	if not check(a.quests.training.equipped == "training_ring", "legacy equipment preserved"): return
	if not check(a.chapter_quests.first_steps.state == 2, "chapter quest preserved"): return
	if not check(store.read_profile("old_b").class_id == "warrior", "second legacy profile warrior"): return
	if not check(store.load_profile("new_a").class_id == "warrior" and not store.read_profile("new_a").class_selected, "new profile warrior placeholder, selection pending"): return
	if not check(not store.is_valid_class_id("hacker") and store.is_valid_class_id("bard"), "server class whitelist"): return
	if not check(not store.assign_class("old_a", "hacker"), "invalid class cannot be assigned"): return
	if not check(not store.assign_class("old_a", "mage") and store.read_profile("old_a").class_id == "warrior", "legacy warrior is locked"): return
	if not check(store.assign_class("new_a", "mage") and store.read_profile("new_a").class_id == "mage", "new profile can choose class once"): return
	if not check(not store.assign_class("new_a", "bard"), "second class choice denied"): return
	if not check(store.read_profile("old_b").class_id == "warrior", "other profile class unaffected"): return
	store = null
	var again := LunexProgressStore.new()
	if not check(again.open(old_path), "idempotent migration reopens"): return
	if not check(again.read_profile("new_a").class_id == "mage", "reopen does not overwrite chosen class"): return
	if not check(again.read_profile("old_a").chapter_quests.first_steps.state == 2, "reopen keeps chapter state"): return
	var fresh := LunexProgressStore.new()
	if not check(fresh.open(new_path) and fresh.load_profile("fresh").class_id == "warrior", "fresh database default warrior"): return
	for id in ["warrior", "mage", "priest", "bard"]:
		var resource: LunexClassDefinition = load("res://game/combat/classes/" + id + ".tres")
		if not check(resource != null and resource.class_id == id and resource.is_valid(), "editable class resource " + id): return
	var broken := LunexProgressStore.new()
	if not check(not broken.open(broken_path), "malformed legacy schema rejected"): return
	print("STAGE771_TOTAL=", count)
	quit()
