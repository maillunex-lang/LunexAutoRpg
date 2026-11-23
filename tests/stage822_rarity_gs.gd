extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var store := LunexProgressStore.new()
	if not store.open("user://stage822_rarity.sqlite"):
		quit(1)
		return
	var profile := "rarity_" + str(Time.get_ticks_usec())
	store.load_profile(profile)
	if LunexProgressStore.gear_score_for_item(0,0) != 0 or LunexProgressStore.gear_score_for_item(6,0) != 0:
		push_error("Invalid rarity accepted")
		quit(1)
		return
	for r in range(1,5):
		if LunexProgressStore.gear_score_for_item(r+1,0) <= LunexProgressStore.gear_score_for_item(r,0):
			push_error("Rarity GS not monotonic")
			quit(1)
			return
	if not store.chapter_accept(profile,"rarity_test") or not store.chapter_advance(profile,"rarity_test",1,1) or not store.chapter_complete(profile,"rarity_test",1,20,"mist_bell_relic",3):
		push_error("Rare reward grant failed")
		quit(1)
		return
	if not store.equip_inventory_item(profile,"mist_bell_relic"):
		push_error("Equip failed")
		quit(1)
		return
	var state := store.read_profile(profile)
	if state.gear_score != 300 or int(state.inventory[0].rarity) != 3:
		push_error("GS/rarity not persisted")
		quit(1)
		return
	print("STAGE822_RARITY_TOTAL=7")
	quit()
