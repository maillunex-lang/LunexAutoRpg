class_name LunexItemCatalog
extends RefCounted

const ITEM_PATHS := [
    "res://game/progression/items/starter_weapon.tres",
    "res://game/progression/items/starter_armor.tres",
    "res://game/progression/items/starter_helmet.tres",
    "res://game/progression/items/starter_gloves.tres",
    "res://game/progression/items/starter_boots.tres",
    "res://game/progression/items/starter_accessory.tres",
]

static func find(item_id: String) -> LunexItemDefinition:
    for path in ITEM_PATHS:
        var item := load(path) as LunexItemDefinition
        if item != null and item.is_valid() and item.item_id == item_id:
            return item
    return null

static func all_items() -> Array[LunexItemDefinition]:
    var result: Array[LunexItemDefinition] = []
    for path in ITEM_PATHS:
        var item := load(path) as LunexItemDefinition
        if item != null and item.is_valid():
            result.append(item)
    return result
