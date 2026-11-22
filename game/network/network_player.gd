class_name LunexNetworkPlayer
extends LunexPlayer

@export_range(0.5, 4.0, 0.1) var attack_range := 1.5
@export_range(1, 1000) var attack_damage := 20
@export_range(0.1, 5.0, 0.05) var attack_interval := 0.8

@onready var navigation: NavigationAgent3D = $NavigationAgent3D

var enemy: LunexTrainingEnemy
var auto_enabled := false
var attack_requested := false
var attack_cooldown := 0.0

var peer_id: int
var display_name: String
var desired_direction := Vector3.ZERO
var input_time_left := 0.0
var server_position := Vector3.ZERO
var server_heading := 0.0

func prepare(id: int, spawn_position: Vector3, player_name: String) -> void:
	peer_id = id
	position = spawn_position
	server_position = spawn_position
	display_name = player_name
	$PlayerName.text = display_name

func accept_input(direction: Vector3) -> void:
	desired_direction = direction.limit_length()
	input_time_left = 0.4
	if desired_direction.length_squared() > 0.001:
		auto_enabled = false

func set_auto(enabled: bool) -> void:
	if enabled and not auto_enabled and enemy.health > 0:
		navigation.target_position = enemy.global_position
	auto_enabled = enabled and enemy.health > 0

func _can_attack() -> bool:
	if enemy.health <= 0 or global_position.distance_squared_to(enemy.global_position) > attack_range * attack_range:
		return false
	var height := Vector3.UP * 0.5
	var sight := PhysicsRayQueryParameters3D.create(global_position + height, enemy.global_position + height, 1)
	return get_world_3d().direct_space_state.intersect_ray(sight).is_empty()

func _attack() -> void:
	if attack_cooldown > 0.0:
		return
	var facing := enemy.global_position - global_position
	$Model.rotation.y = atan2(facing.x, facing.z)
	attack_cooldown = attack_interval
	enemy.take_hit(attack_damage, peer_id)
	if enemy.health <= 0:
		auto_enabled = false

func _auto_direction() -> Vector3:
	if enemy.health <= 0:
		auto_enabled = false
		return Vector3.ZERO
	if _can_attack():
		_attack()
		return Vector3.ZERO
	if navigation.is_navigation_finished():
		auto_enabled = false
		return Vector3.ZERO
	var step := navigation.get_next_path_position() - global_position
	step.y = 0.0
	return step.normalized()

func _ready() -> void:
	if not multiplayer.is_server():
		collision_layer = 0
		collision_mask = 0

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		input_time_left = maxf(input_time_left - delta, 0.0)
		var direction := desired_direction if input_time_left > 0.0 else Vector3.ZERO
		attack_cooldown = maxf(attack_cooldown - delta, 0.0)
		if auto_enabled:
			direction = _auto_direction()
		if attack_requested:
			attack_requested = false
			if _can_attack():
				_attack()
		simulate(direction, delta)
		server_position = position
		server_heading = $Model.rotation.y
		return

	var weight := 1.0 - exp(-22.0 * delta)
	position = position.lerp(server_position, weight)
	$Model.rotation.y = lerp_angle($Model.rotation.y, server_heading, weight)
