extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var store := LunexProgressStore.new()
	if not store.open("user://stage821_equipment.sqlite"):
		quit(1)
		return
	var profile := "gear_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	if LunexProgressStore.EQUIPMENT_SLOTS.size() != 6:
		push_error("Missing six slots")
		quit(1)
		return
	if store.equip_inventory_item(profile,"nonexistent"):
		push_error("Forged equip accepted")
		quit(1)
		return
	if not store.chapter_accept(profile,"item_test") or not store.chapter_advance(profile,"item_test",1,1) or not store.chapter_complete(profile,"item_test",1,20,"ash_guard_charm"):
		push_error("Reward grant failed")
		quit(1)
		return
	if not store.equip_inventory_item(profile,"ash_guard_charm"):
		push_error("Owned item cannot equip")
		quit(1)
		return
	var state := store.read_profile(profile)
	if state.inventory.size() != 1 or state.equipped_slots.get("accessory","") != "ash_guard_charm":
		push_error("Inventory/equip not persisted")
		quit(1)
		return
	print("STAGE821_EQUIPMENT_TOTAL=6")
	quit()
