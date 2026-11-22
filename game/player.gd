extends CharacterBody3D

@export var camera: Camera3D
@export var joystick: LunexVirtualJoystick

@export_range(0.0, 20.0, 0.1) var speed := 4.5

func _physics_process(delta: float) -> void:
	var direction := camera_relative_direction(joystick.output)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	if direction.length_squared() > 0.0:
		$Model.rotation.y = atan2(direction.x, direction.z)
	move_and_slide()

func camera_relative_direction(input: Vector2) -> Vector3:
	var right := camera.global_transform.basis.x
	var back := camera.global_transform.basis.z
	right.y = 0.0
	back.y = 0.0
	return right.normalized() * input.x + back.normalized() * input.y
