extends Camera3D

@export var target: Node3D
@export var follow_offset := Vector3(0, 8, 9)
@export var look_offset := Vector3(0, 0.8, 0)

@export_range(0.1, 30.0, 0.1) var follow_speed := 10.0

func _ready() -> void:
	global_position = target.global_position + follow_offset
	look_at(target.global_position + look_offset)

func _physics_process(delta: float) -> void:
	var destination := target.global_position + follow_offset
	global_position = global_position.lerp(destination, 1.0 - exp(-follow_speed * delta))
