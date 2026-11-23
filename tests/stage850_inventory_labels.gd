extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if LunexProgressHUD.item_display_name("starter_weapon") != "Клинок странника":
		push_error("STAGE850 catalog title mismatch")
		quit(1)
		return
	if LunexProgressHUD.item_display_name("legacy_unknown") != "legacy_unknown":
		push_error("STAGE850 legacy fallback mismatch")
		quit(1)
		return
	var expected := ["Оружие", "Броня", "Шлем", "Перчатки", "Обувь", "Аксессуар"]
	for i in range(LunexProgressStore.EQUIPMENT_SLOTS.size()):
		if LunexProgressHUD.slot_display_name(LunexProgressStore.EQUIPMENT_SLOTS[i]) != expected[i]:
			push_error("STAGE850 slot label mismatch")
			quit(1)
			return
	for rarity in range(1, 6):
		if LunexProgressHUD.rarity_display_name(rarity) == "Неизвестный":
			push_error("STAGE850 rarity label mismatch")
			quit(1)
			return
	print("STAGE850_LABELS=PASS editable_item_names six_slots five_rarities legacy_fallback")
	quit(0)
