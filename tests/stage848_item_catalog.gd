extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var catalog := LunexItemCatalog.all_items()
	if catalog.size() != 6:
		push_error("STAGE848 catalog count")
		quit(1)
		return
	var seen := {}
	var store := LunexProgressStore.new()
	if not store.open("user://stage848_catalog.sqlite"):
		quit(1)
		return
	var profile := "catalog_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	for item in catalog:
		if seen.has(item.slot) or not item.is_valid() or LunexProgressStore.equipment_slot_for_item(item.item_id) != item.slot:
			push_error("STAGE848 invalid catalog slot")
			quit(1)
			return
		seen[item.slot] = true
		if not store.chapter_accept(profile,item.item_id) or not store.chapter_advance(profile,item.item_id,1,1) or not store.chapter_complete(profile,item.item_id,1,10,item.item_id,item.rarity,100):
			push_error("STAGE848 cannot grant "+item.item_id)
			quit(1)
			return
		if not store.equip_inventory_item(profile,item.item_id):
			push_error("STAGE848 cannot equip "+item.item_id)
			quit(1)
			return
	if store.chapter_accept(profile,"forged_starter") and store.chapter_advance(profile,"forged_starter",1,1):
		if store.chapter_complete(profile,"forged_starter",1,10,"starter_hacked_weapon",1,100):
			push_error("STAGE848 forged catalog item granted")
			quit(1)
			return
	# Completed chapter must not mint duplicate gold, XP or items.
	if store.chapter_complete(profile, catalog[0].item_id, 1, 10, catalog[0].item_id, 1, 100):
		push_error("STAGE848 duplicate chapter reward accepted")
		quit(1)
		return
	var state := store.read_profile(profile)
	if int(state.get("experience", 0)) != 60:
		push_error("STAGE848 duplicate XP")
		quit(1)
		return
	if state.inventory.size() != 6 or state.equipped_slots.size() != 6 or int(state.gear_score) != 600 or int(state.gold) != 600:
		push_error("STAGE848 incorrect saved inventory "+str(state))
		quit(1)
		return
	print("STAGE848_CATALOG=PASS six_editor_resources six_equipped forged_rejected sqlite")
	quit(0)
