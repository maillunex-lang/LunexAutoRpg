class_name LunexClassDefinition
extends Resource

@export var class_id: String = "warrior"
@export var display_name: String = "Воин"
@export_enum("tank", "damage", "healer", "support") var role: String = "tank"
@export_range(1, 10000, 1) var base_health: int = 100
@export_range(1, 1000, 1) var base_damage: int = 20
@export_range(0.1, 5.0, 0.05) var attack_interval: float = 0.8
@export var icon: Texture2D
@export var ability_ids: PackedStringArray = PackedStringArray()

func is_valid() -> bool:
	return class_id in ["warrior", "mage", "priest", "bard"] and role in ["tank", "damage", "healer", "support"] and base_health > 0 and base_damage > 0 and attack_interval >= 0.1
