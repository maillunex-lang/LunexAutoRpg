class_name LunexNetworkPlayer
extends LunexPlayer

@export_range(0.5, 4.0, 0.1) var attack_range := 1.5
@export_range(1, 1000) var attack_damage := 20
@export_range(0.1, 5.0, 0.05) var attack_interval := 0.8

@export_range(1, 1000) var max_health := 100
@export_range(0.5, 20.0, 0.1) var revival_delay := 4.0

@onready var navigation: NavigationAgent3D = $NavigationAgent3D

var health := 100
var ability_energy := 100.0
var shield_points := 0
var shield_expires_ms := 0
var revival_left := 0.0
var _spawn_position := Vector3.ZERO
var _was_alive := true
var _standing_collision_layer: int

var enemy: LunexTrainingEnemy
var auto_enabled := false
var quest_auto_enabled := false
var quest_destination := Vector3.ZERO
var attack_requested := false
var attack_cooldown := 0.0

var zone_id := 0
var peer_id: int
var class_id := "warrior"
var display_name: String
var desired_direction := Vector3.ZERO
var input_time_left := 0.0
var server_zone_id := 0
var server_position := Vector3.ZERO
var server_heading := 0.0
var server_moving := false
var attack_sequence := 0
var _seen_attack := -1

func prepare(id: int, spawn_position: Vector3, player_name: String, selected_class: String = "warrior") -> void:
	class_id = selected_class
	peer_id = id
	position = spawn_position
	_spawn_position = spawn_position
	health = max_health
	ability_energy = 100.0
	server_position = spawn_position
	display_name = player_name
	$PlayerName.text = display_name + " [" + _class_label() + "]"

func _class_label() -> String:
	return {"warrior": "Воин", "mage": "Маг", "priest": "Жрец", "bard": "Бард"}.get(class_id, "Воин")

func update_class(selected_class: String) -> void:
	class_id = selected_class
	$PlayerName.text = display_name + " [" + _class_label() + "]"

func has_line_of_sight(target_position: Vector3) -> bool:
	var height := Vector3.UP * 0.5
	var ray := PhysicsRayQueryParameters3D.create(global_position + height, target_position + height, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func apply_shield(points: int, duration_seconds: float) -> void:
	shield_points = maxi(shield_points, points)
	shield_expires_ms = Time.get_ticks_msec() + int(duration_seconds * 1000.0)

func accept_input(direction: Vector3) -> void:
	if health <= 0:
		return
	desired_direction = direction.limit_length()
	input_time_left = 0.4
	if desired_direction.length_squared() > 0.001:
		auto_enabled = false
		quest_auto_enabled = false

func enter_zone(next_zone: int, arrival: Vector3) -> void:
	zone_id = next_zone
	server_zone_id = next_zone
	_spawn_position = arrival
	position = arrival
	server_position = arrival
	velocity = Vector3.ZERO
	desired_direction = Vector3.ZERO
	input_time_left = 0.0
	auto_enabled = false
	quest_auto_enabled = false
	attack_requested = false
	server_moving = false

func set_quest_destination(destination: Vector3) -> void:
	if health <= 0:
		return
	auto_enabled = false
	quest_auto_enabled = true
	quest_destination = destination
	navigation.target_position = destination

func _quest_direction() -> Vector3:
	if global_position.distance_to(quest_destination) <= 1.65:
		quest_auto_enabled = false
		return Vector3.ZERO
	if navigation.is_navigation_finished():
		quest_auto_enabled = false
		return Vector3.ZERO
	var step := navigation.get_next_path_position() - global_position
	step.y = 0.0
	return step.normalized()

func set_target(target: LunexTrainingEnemy) -> void:
	if enemy != target:
		enemy = target
		auto_enabled = false
		quest_auto_enabled = false
		attack_requested = false

func set_auto(enabled: bool) -> void:
	enabled = enabled and health > 0
	if enabled and not auto_enabled and enemy.health > 0:
		navigation.target_position = enemy.global_position
	auto_enabled = enabled and enemy.health > 0

func _can_attack() -> bool:
	if health <= 0 or enemy.health <= 0 or global_position.distance_squared_to(enemy.global_position) > attack_range * attack_range:
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
	attack_sequence += 1
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

func take_counter_damage(damage: int) -> void:
	if health <= 0:
		return
	if Time.get_ticks_msec() >= shield_expires_ms:
		shield_points = 0
	var absorbed := mini(shield_points, damage)
	shield_points -= absorbed
	health = maxi(0, health - (damage - absorbed))
	if health == 0:
		revival_left = revival_delay
		auto_enabled = false
		quest_auto_enabled = false
		attack_requested = false
		server_moving = false
		desired_direction = Vector3.ZERO
		input_time_left = 0.0
		velocity = Vector3.ZERO
		collision_layer = 0

func _revive() -> void:
	position = _spawn_position
	server_position = position
	collision_layer = _standing_collision_layer
	attack_requested = false
	attack_cooldown = 0.0
	health = max_health
	ability_energy = 100.0
	shield_points = 0

func _ready() -> void:
	_standing_collision_layer = collision_layer
	if not multiplayer.is_server():
		collision_layer = 0
		collision_mask = 0

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if health <= 0:
			revival_left = maxf(0.0, revival_left - delta)
			if revival_left <= 0.0:
				_revive()
			return
		input_time_left = maxf(input_time_left - delta, 0.0)
		var direction := desired_direction if input_time_left > 0.0 else Vector3.ZERO
		attack_cooldown = maxf(attack_cooldown - delta, 0.0)
		ability_energy = minf(100.0, ability_energy + delta * 5.0)
		if auto_enabled:
			direction = _auto_direction()
		elif quest_auto_enabled:
			direction = _quest_direction()
		if attack_requested:
			attack_requested = false
			if _can_attack():
				_attack()
		simulate(direction, delta)
		server_position = position
		server_heading = $Model.rotation.y
		var motion := get_real_velocity()
		server_moving = Vector2(motion.x, motion.z).length_squared() > 0.04
		return

	var alive := health > 0
	if alive != _was_alive:
		_was_alive = alive
		if alive:
			position = _spawn_position
			hero_visual.show_motion(false)
		else:
			hero_visual.show_defeat()
	var weight := 1.0 - exp(-22.0 * delta)
	if peer_id != multiplayer.get_unique_id() or zone_id == server_zone_id:
		position = server_position if position.distance_squared_to(server_position) > 144.0 else position.lerp(server_position, weight)
	$Model.rotation.y = lerp_angle($Model.rotation.y, server_heading, weight)
	if _seen_attack != attack_sequence:
		if _seen_attack >= 0 and alive:
			hero_visual.show_attack()
		_seen_attack = attack_sequence
	if alive:
		hero_visual.show_motion(server_moving)
