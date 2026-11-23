class_name LunexAbilityDefinition
extends Resource

@export var ability_id: String = ""
@export_enum("warrior", "mage", "priest", "bard") var class_id: String = "warrior"
@export_range(1, 100, 1) var unlock_level: int = 1
@export_range(0.0, 60.0, 0.05) var cooldown_seconds: float = 1.0
@export_range(0, 1000, 1) var resource_cost: int = 0
@export_range(0.1, 50.0, 0.1) var max_range: float = 2.0
@export_enum("enemy", "self", "ally") var target_kind: String = "enemy"
@export_enum("damage", "heal", "status") var effect_kind: String = "damage"
@export_range(0, 10000, 1) var magnitude: int = 0
@export var status_id: String = ""
@export_range(0.0, 120.0, 0.1) var status_duration: float = 0.0

func is_valid() -> bool:
	return not ability_id.is_empty() and class_id in ["warrior", "mage", "priest", "bard"] and unlock_level >= 1 and cooldown_seconds >= 0.0 and max_range > 0.0 and resource_cost >= 0 and magnitude >= 0 and magnitude <= 10000 and resource_cost <= 1000 and max_range <= 50.0 and cooldown_seconds <= 60.0 and status_duration <= 120.0 and target_kind in ["enemy", "self", "ally"] and effect_kind in ["damage", "heal", "status"] and (effect_kind != "status" or (not status_id.is_empty() and status_duration > 0.0))
