extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var store := LunexProgressStore.new()
	if not store.open("user://stage823_upgrade.sqlite"):
		quit(1)
		return
	var profile := "upgrade_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	if store.upgrade_inventory_item(profile,"fake"):
		push_error("Forged upgrade")
		quit(1)
		return
	if not store.chapter_accept(profile,"upgrade_test") or not store.chapter_advance(profile,"upgrade_test",1,1) or not store.chapter_complete(profile,"upgrade_test",1,10,"ash_guard_charm",2,50):
		push_error("Gold/item grant failed")
		quit(1)
		return
	if not store.equip_inventory_item(profile,"ash_guard_charm") or not store.upgrade_inventory_item(profile,"ash_guard_charm"):
		push_error("First upgrade failed")
		quit(1)
		return
	if store.upgrade_inventory_item(profile,"ash_guard_charm"):
		push_error("Insufficient gold bypass")
		quit(1)
		return
	var state := store.read_profile(profile)
	if state.gold != 0 or state.gear_score != 225 or state.inventory.size() != 1 or int(state.inventory[0].upgrade_level) != 1:
		push_error("Upgrade state/GS invalid")
		quit(1)
		return
	print("STAGE823_UPGRADE_TOTAL=5")
	quit()
