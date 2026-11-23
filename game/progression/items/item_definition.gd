class_name LunexItemDefinition
extends Resource

@export var item_id := ""
@export var display_name := ""
@export_enum("weapon", "armor", "helmet", "gloves", "boots", "accessory") var slot := "weapon"
@export_range(1, 5) var rarity := 1
@export_multiline var description := ""

func is_valid() -> bool:
	return not item_id.is_empty() and item_id.length() <= 64 and not display_name.is_empty() and slot in LunexProgressStore.EQUIPMENT_SLOTS and rarity >= 1 and rarity <= 5
