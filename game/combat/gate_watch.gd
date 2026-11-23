class_name LunexGateWatch
extends LunexTrainingEnemy

@export_range(1, 100) var counter_damage := 20
@export_range(0.5, 10.0, 0.1) var counter_radius := 2.2
@export_range(0.1, 10.0, 0.05) var warning_duration := 0.9
@export_range(0.1, 20.0, 0.05) var counter_cooldown := 2.5
@export var counter_clip: StringName = &"1H_Melee_Attack_Slice_Horizontal"
@export var proactive_aggro := true
@export_range(0.1, 5.0, 0.1) var perception_interval := 0.5
@export_range(0.5, 30.0, 0.5) var disengage_delay := 5.0

@onready var warning: MeshInstance3D = $CounterWarning

var players: Node3D
var telegraph_active := false
var counter_sequence := 0
var _provoked := false
var _time_left := 0.0
var _seen_counter := -1
var _perception_left := 0.0
var _disengage_left := 0.0
# Server-only engagement state; the telegraph remains the replicated visual truth.
enum BrainState { IDLE, ALERT, WINDUP, RECOVERY, DEAD }
var brain_state := BrainState.IDLE
var _threat: Dictionary[int, float] = {}

func _ready() -> void:
	super._ready()
	warning.scale = Vector3(counter_radius, 1.0, counter_radius)
	hit_landed.connect(_register_threat)
	defeated.connect(_reset_counter)
	clips.animation_finished.connect(_return_to_idle)

func _process(delta: float) -> void:
	super._process(delta)
	warning.visible = health > 0 and telegraph_active
	if _seen_counter != counter_sequence:
		if _seen_counter >= 0 and health > 0:
			clips.play(counter_clip, 0.05)
		_seen_counter = counter_sequence

func _register_threat(peer_id: int) -> void:
	_provoked = true
	brain_state = BrainState.ALERT
	_threat[peer_id] = _threat.get(peer_id, 0.0) + (definition.damage_threat_factor if definition != null else 1.0)

func add_support_threat(peer_id: int, effective_amount: float) -> void:
	# Only support actions during actual combat generate threat.
	if not multiplayer.is_server() or not _provoked or health <= 0 or effective_amount <= 0.0:
		return
	_threat[peer_id] = _threat.get(peer_id, 0.0) + effective_amount * (definition.healing_threat_factor if definition != null else 0.7)

func primary_threat_peer() -> int:
	var best_peer := -1
	var best_threat := -1.0
	for id in _threat:
		var amount: float = _threat[id]
		if amount > best_threat:
			best_threat = amount
			best_peer = id
	return best_peer

func _has_nearby_player(radius: float) -> bool:
	if players == null:
		return false
	for child in players.get_children():
		var candidate := child as LunexNetworkPlayer
		if candidate != null and candidate.zone_id == zone_id and candidate.health > 0 and global_position.distance_squared_to(candidate.global_position) <= radius * radius and candidate.has_line_of_sight(global_position):
			return true
	return false

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or players == null:
		return
	if health <= 0:
		brain_state = BrainState.DEAD
		return
	_perception_left -= delta
	if _perception_left <= 0.0:
		_perception_left = perception_interval
		var leash := definition.leash_radius if definition != null else 14.0
		var detection := definition.aggro_radius if definition != null else 6.0
		if not _provoked and proactive_aggro and _has_nearby_player(detection):
			_provoked = true
			brain_state = BrainState.ALERT
		elif _provoked:
			if _has_nearby_player(leash):
				_disengage_left = 0.0
			else:
				_disengage_left += perception_interval
				if _disengage_left >= disengage_delay:
					_reset_counter()
	if not _provoked:
		return
	_time_left -= delta
	if _time_left > 0.0:
		return
	var victims := _players_in_range()
	if telegraph_active:
		telegraph_active = false
		brain_state = BrainState.RECOVERY
		_time_left = counter_cooldown
		counter_sequence += 1
		for player in victims:
			player.take_counter_damage(counter_damage)
	elif not victims.is_empty():
		telegraph_active = true
		brain_state = BrainState.WINDUP
		_time_left = warning_duration
	else:
		brain_state = BrainState.ALERT

func _players_in_range() -> Array[LunexNetworkPlayer]:
	var victims: Array[LunexNetworkPlayer] = []
	var origin := global_position + Vector3.UP * 0.5
	for child in players.get_children():
		var player := child as LunexNetworkPlayer
		if player == null or player.zone_id != zone_id or player.health <= 0 or global_position.distance_squared_to(player.global_position) > counter_radius * counter_radius:
			continue
		var sight := PhysicsRayQueryParameters3D.create(origin, player.global_position + Vector3.UP * 0.5, 1)
		if get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
			victims.append(player)
	return victims

func _reset_counter() -> void:
	_provoked = false
	telegraph_active = false
	_time_left = 0.0
	_disengage_left = 0.0
	_threat.clear()
	brain_state = BrainState.IDLE

func _return_to_idle(clip: StringName) -> void:
	if clip == counter_clip and health > 0:
		clips.play(idle_clip, 0.08)
