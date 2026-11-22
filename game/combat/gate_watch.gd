class_name LunexGateWatch
extends LunexTrainingEnemy

@export_range(1, 100) var counter_damage := 20
@export_range(0.5, 10.0, 0.1) var counter_radius := 2.2
@export_range(0.1, 10.0, 0.05) var warning_duration := 0.9
@export_range(0.1, 20.0, 0.05) var counter_cooldown := 2.5
@export var counter_clip: StringName = &"1H_Melee_Attack_Slice_Horizontal"

@onready var warning: MeshInstance3D = $CounterWarning

var players: Node3D
var telegraph_active := false
var counter_sequence := 0
var _provoked := false
var _time_left := 0.0
var _seen_counter := -1

func _ready() -> void:
	super._ready()
	warning.scale = Vector3(counter_radius, 1.0, counter_radius)
	hit_landed.connect(func(_peer_id: int) -> void: _provoked = true)
	defeated.connect(_reset_counter)
	clips.animation_finished.connect(_return_to_idle)

func _process(delta: float) -> void:
	super._process(delta)
	warning.visible = health > 0 and telegraph_active
	if _seen_counter != counter_sequence:
		if _seen_counter >= 0 and health > 0:
			clips.play(counter_clip, 0.05)
		_seen_counter = counter_sequence

func _physics_process(delta: float) -> void:
	if players == null or not _provoked or health <= 0:
		return
	_time_left -= delta
	if _time_left > 0.0:
		return
	var victims := _players_in_range()
	if telegraph_active:
		telegraph_active = false
		_time_left = counter_cooldown
		counter_sequence += 1
		for player in victims:
			player.take_counter_damage(counter_damage)
	elif not victims.is_empty():
		telegraph_active = true
		_time_left = warning_duration

func _players_in_range() -> Array[LunexNetworkPlayer]:
	var victims: Array[LunexNetworkPlayer] = []
	var origin := global_position + Vector3.UP * 0.5
	for child in players.get_children():
		var player := child as LunexNetworkPlayer
		if player.health <= 0 or global_position.distance_squared_to(player.global_position) > counter_radius * counter_radius:
			continue
		var sight := PhysicsRayQueryParameters3D.create(origin, player.global_position + Vector3.UP * 0.5, 1)
		if get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
			victims.append(player)
	return victims

func _reset_counter() -> void:
	_provoked = false
	telegraph_active = false
	_time_left = 0.0

func _return_to_idle(clip: StringName) -> void:
	if clip == counter_clip and health > 0:
		clips.play(idle_clip, 0.08)
