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
	health = max_health
	clips.get_animation(idle_clip).loop_mode = Animation.LOOP_LINEAR
	clips.get_animation(defeated_clip).loop_mode = Animation.LOOP_NONE
	clips.play(idle_clip)
	$Respawn.timeout.connect(func() -> void: health = max_health)

func _process(_delta: float) -> void:
	var alive := health > 0
	if alive == _was_alive:
		return
	_was_alive = alive
	$Name.visible = alive
	clips.play(idle_clip if alive else defeated_clip, 0.08)

func take_hit(damage: int, peer_id: int) -> void:
	if health <= 0:
		return
	health = maxi(health - damage, 0)
	hit_landed.emit(peer_id)
	if health == 0:
		$Respawn.start(respawn_delay)
		defeated.emit()
