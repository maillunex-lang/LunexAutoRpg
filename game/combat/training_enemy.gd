class_name LunexTrainingEnemy
extends Node3D

signal hit_landed(peer_id: int)
signal defeated

@export var zone_id := 0
@export var target_id := "training"
@export var definition: LunexEnemyDefinition
@export var target_name := "Тренировочная цель"
@export_range(1, 1000) var max_health := 60
@export_range(0.5, 60.0) var respawn_delay := 4.0
@export var idle_clip: StringName = &"Idle_Combat"
@export var defeated_clip: StringName = &"Death_A"

@onready var clips: AnimationPlayer = $EnemyVisual/AnimationPlayer
@onready var _nav: NavigationAgent3D = $NavigationAgent3D
@onready var _ai_warning: MeshInstance3D = $AIWarning

# AI only updates on authoritative server. Position and warnings replicate to clients.
enum AIState { IDLE, PATROL, ALERT, CHASE, WINDUP, RECOVERY, RETURN, DEAD }
var ai_state := AIState.IDLE
var ai_warning_active := false
var is_elite := false
var ai_players: Node3D
var ai_basic_attack := true
var _ai_target: LunexNetworkPlayer
var _threat_scores: Dictionary[int, float] = {}
var _home := Vector3.ZERO
var _scan_left := 0.0
var _repath_left := 0.0
var _action_left := 0.0
var _patrol_target := Vector3.ZERO
var _patrol_sign := 1.0


var health: int
var _was_alive := true

func _ready() -> void:
	if definition != null:
		if not definition.is_valid_definition():
			push_error("Invalid enemy definition: " + name)
		else:
			# Quest target_id remains unchanged; the new stable instance ID is separate.
			target_id = definition.target_id
			target_name = definition.target_name
			zone_id = definition.zone_id
			max_health = definition.max_health
			respawn_delay = definition.respawn_delay
	$Name.text = target_name
	_home = global_position
	_patrol_target = _home
	health = max_health
	clips.get_animation(idle_clip).loop_mode = Animation.LOOP_LINEAR
	clips.get_animation(defeated_clip).loop_mode = Animation.LOOP_NONE
	clips.play(idle_clip)
	$Respawn.timeout.connect(_respawn_after_delay)

func _process(_delta: float) -> void:
	var alive := health > 0
	_ai_warning.visible = ai_warning_active and alive
	if $Name.text != target_name:
		$Name.text = target_name
		$Name.modulate = Color(1.0, 0.76, 0.25) if is_elite else Color.WHITE
	if alive == _was_alive:
		return
	_was_alive = alive
	$Name.visible = alive
	_ai_warning.visible = ai_warning_active and alive
	clips.play(idle_clip if alive else defeated_clip, 0.08)

func take_hit(damage: int, peer_id: int) -> void:
	if health <= 0:
		return
	health = maxi(health - damage, 0)
	if multiplayer.is_server() and peer_id > 0:
		_threat_scores[peer_id] = _threat_scores.get(peer_id, 0.0) + float(maxi(damage, 1)) * (definition.damage_threat_factor if definition != null else 1.0)
		_scan_left = 0.0
	hit_landed.emit(peer_id)
	if health == 0:
		$Respawn.start(respawn_delay)
		defeated.emit()

func _respawn_after_delay() -> void:
	if multiplayer.is_server():
		if definition != null:
			is_elite = randf() < definition.elite_spawn_chance
			max_health = ceili(float(definition.max_health) * (definition.elite_health_multiplier if is_elite else 1.0))
			target_name = definition.target_name + (" [Элита]" if is_elite else "")
		global_position = _home
		_threat_scores.clear()
		_ai_target = null
		ai_state = AIState.IDLE
		ai_warning_active = false
		_action_left = 0.0
	health = max_health

func add_healing_threat(peer_id: int, effective_heal: float) -> void:
	if not multiplayer.is_server() or health <= 0 or _ai_target == null or effective_heal <= 0.0:
		return
	_threat_scores[peer_id] = _threat_scores.get(peer_id, 0.0) + effective_heal * (definition.healing_threat_factor if definition != null else 0.7)

func _can_see_ai_target(other: LunexNetworkPlayer) -> bool:
	if not is_instance_valid(other) or other.health <= 0 or other.zone_id != zone_id:
		return false
	return other.has_line_of_sight(global_position)

func _scan_for_ai_target() -> void:
	if ai_players == null:
		return
	var best: LunexNetworkPlayer
	var best_score := -INF
	var leash: float = definition.leash_radius if definition != null else 14.0
	var aggro: float = definition.aggro_radius if definition != null else 5.0
	for child in ai_players.get_children():
		var candidate := child as LunexNetworkPlayer
		if candidate == null or candidate.health <= 0 or candidate.zone_id != zone_id:
			continue
		var d := _home.distance_to(candidate.global_position)
		if d > leash or (global_position.distance_to(candidate.global_position) > aggro and not _threat_scores.has(candidate.peer_id)):
			continue
		if not _can_see_ai_target(candidate):
			continue
		var score: float = _threat_scores.get(candidate.peer_id, 1.0) - d * 0.02
		if score > best_score:
			best = candidate
			best_score = score
	_ai_target = best

func _navigate_ai(destination: Vector3, speed: float, delta: float) -> void:
	_repath_left -= delta
	if _repath_left <= 0.0:
		_repath_left = 0.3
		_nav.target_position = destination
	if _nav.is_navigation_finished():
		return
	var direction := _nav.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return
	global_position += direction.normalized() * minf(speed * delta, direction.length())

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or ai_players == null:
		return
	if health <= 0:
		ai_state = AIState.DEAD
		ai_warning_active = false
		return
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = 0.5
		_scan_for_ai_target()
	var leash: float = definition.leash_radius if definition != null else 14.0
	if _home.distance_to(global_position) > leash or (_ai_target != null and _home.distance_to(_ai_target.global_position) > leash):
		_ai_target = null
		_threat_scores.clear()
	if _ai_target == null:
		ai_warning_active = false
		if global_position.distance_to(_home) > 0.6:
			ai_state = AIState.RETURN
			_navigate_ai(_home, definition.chase_speed if definition != null else 2.6, delta)
			return
		var radius: float = definition.patrol_radius if definition != null else 0.0
		if radius > 0.0:
			if _patrol_target == _home or global_position.distance_to(_patrol_target) <= 0.4:
				_patrol_sign *= -1.0
				_patrol_target = _home + Vector3(radius * _patrol_sign, 0.0, 0.0)
			ai_state = AIState.PATROL
			_navigate_ai(_patrol_target, definition.patrol_speed, delta)
		else:
			ai_state = AIState.IDLE
		return
	var reach: float = definition.melee_range if definition != null else 1.8
	var distance := global_position.distance_to(_ai_target.global_position)
	if distance > reach or not _can_see_ai_target(_ai_target):
		ai_warning_active = false
		ai_state = AIState.CHASE
		_navigate_ai(_ai_target.global_position, definition.chase_speed if definition != null else 2.6, delta)
		return
	if not ai_basic_attack:
		ai_state = AIState.ALERT
		return
	if ai_state != AIState.WINDUP and ai_state != AIState.RECOVERY:
		ai_state = AIState.WINDUP
		ai_warning_active = true
		_action_left = definition.windup_duration if definition != null else 0.7
	_action_left -= delta
	if _action_left > 0.0:
		return
	if ai_state == AIState.WINDUP:
		ai_warning_active = false
		if _can_see_ai_target(_ai_target) and global_position.distance_to(_ai_target.global_position) <= reach:
			var damage: int = definition.melee_damage if definition != null else 8
			if is_elite and definition != null:
				damage = ceili(float(damage) * definition.elite_damage_multiplier)
			_ai_target.take_counter_damage(damage)
		ai_state = AIState.RECOVERY
		_action_left = definition.attack_cooldown if definition != null else 2.0
	else:
		ai_state = AIState.WINDUP
		ai_warning_active = true
		_action_left = definition.windup_duration if definition != null else 0.7
