class_name LunexHudLayoutPreset
extends Resource

@export var preset_name: String = "Стандарт"
@export_range(0.65, 1.35, 0.05) var action_scale: float = 1.0
@export_range(0.65, 1.35, 0.05) var joystick_scale: float = 1.0
@export_range(0.0, 128.0, 1.0) var edge_margin: float = 24.0
@export var actions_right: bool = true

func normalized_scale(value: float) -> float:
	return clampf(value, 0.65, 1.35)
