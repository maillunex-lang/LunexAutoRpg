extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "user://content845_migration_%d.sqlite" % Time.get_ticks_usec()
	var store := LunexProgressStore.new()
	if not store.open(path):
		push_error("Cannot open new profile DB")
		quit(1)
		return
	var profile := "legacy"
	store.load_profile(profile)
	if not store.chapter_accept(profile, "legacy_ring") or not store.chapter_advance(profile, "legacy_ring", 1, 1) or not store.chapter_complete(profile, "legacy_ring", 1, 0, "legacy_ring", 3):
		push_error("Cannot seed legacy item")
		quit(1)
		return
	if not store.equip_inventory_item(profile, "legacy_ring"):
		push_error("Cannot equip legacy item")
		quit(1)
		return
	var db: Object = store._db
	if not db.query_with_bindings("UPDATE equipment_items SET slot = 'ring' WHERE profile = ? AND item_id = ?", [profile,"legacy_ring"]):
		push_error("Cannot seed old slot")
		quit(1)
		return
	if not db.query_with_bindings("UPDATE equipped_slots SET slot = 'ring' WHERE profile = ?", [profile]):
		push_error("Cannot seed old equipped slot")
		quit(1)
		return
	store = LunexProgressStore.new()
	if not store.open(path):
		push_error("Cannot migrate old DB")
		quit(1)
		return
	var state := store.read_profile(profile)
	if state.inventory.size() != 1 or state.inventory[0].slot != "accessory" or state.equipped_slots.get("accessory","") != "legacy_ring" or int(state.gear_score) != 300:
		push_error("Legacy slot or GS lost: "+str(state))
		quit(1)
		return
	var again := LunexProgressStore.new()
	if not again.open(path):
		push_error("Idempotent reopen failed")
		quit(1)
		return
	var state2 := again.read_profile(profile)
	if state2.inventory.size() != 1 or state2.equipped_slots.size() != 1:
		push_error("Migration duplicated equipment")
		quit(1)
		return
	print("STAGE845_MIGRATION=PASS legacy_ring_to_accessory old_item_kept gs_kept idempotent")
	quit(0)
