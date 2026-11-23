extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var store := LunexProgressStore.new()
	if not store.open("user://content844_inventory.sqlite"):
		push_error("SQLite unavailable")
		quit(1)
		return
	var profile := "inventory_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	var slots := LunexProgressStore.EQUIPMENT_SLOTS
	for slot in slots:
		var item_id: String = "test_" + slot
		var quest_id: String = "test_" + slot
		if LunexProgressStore.equipment_slot_for_item(item_id) != slot:
			push_error("Wrong equipment slot for " + slot)
			quit(1)
			return
		if not store.chapter_accept(profile, quest_id) or not store.chapter_advance(profile, quest_id, 1, 1) or not store.chapter_complete(profile, quest_id, 1, 0, item_id, 2, 100):
			push_error("Could not grant item " + item_id)
			quit(1)
			return
		if not store.equip_inventory_item(profile, item_id):
			push_error("Could not equip " + item_id)
			quit(1)
			return
	if store.equip_inventory_item(profile, "forged_helmet") or store.upgrade_inventory_item(profile, "forged_helmet"):
		push_error("Forged item operation accepted")
		quit(1)
		return
	var state := store.read_profile(profile)
	if state.inventory.size() != 6 or state.equipped_slots.size() != 6 or int(state.gear_score) != 1200:
		push_error("Six slots or gear score mismatch: " + str(state))
		quit(1)
		return
	if not store.upgrade_inventory_item(profile, "test_weapon"):
		push_error("Upgrade with gold failed")
		quit(1)
		return
	state = store.read_profile(profile)
	if int(state.gear_score) != 1225 or int(state.gold) != 550:
		push_error("Upgrade balance wrong")
		quit(1)
		return
	var hud: LunexProgressHUD = load("res://game/progression/progress_hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	var reward: LunexQuestReward = load("res://game/progression/quest_1.tres") if ResourceLoader.exists("res://game/progression/quest_1.tres") else null
	var rewards: Array[LunexQuestReward] = []
	if reward != null:
		rewards.append(reward)
	else:
		var fallback := LunexQuestReward.new()
		fallback.quest_id = "test"
		rewards.append(fallback)
	hud.show_state(state, rewards, 50)
	var list: ItemList = hud.get_node("InventoryPanel/InventoryMargin/InventoryFields/InventoryItems")
	if list.item_count != 6 or not hud.get_node("InventoryPanel/InventoryMargin/InventoryFields/InventorySlots").text.contains("GS: 1225"):
		push_error("Inventory UI not populated")
		quit(1)
		return
	var equip_button: Button = hud.get_node("InventoryPanel/InventoryMargin/InventoryFields/InventoryEquip")
	if not equip_button.disabled:
		push_error("Already-equipped item should be disabled")
		quit(1)
		return
	print("STAGE844_INVENTORY=PASS six_slots sqlite_upgrade_gs forged_rejected native_ui")
	quit(0)
