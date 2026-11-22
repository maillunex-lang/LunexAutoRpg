class_name LunexTrainingEnemy
extends Node3D

@export_range(1, 1000) var max_health := 60
@export_range(0.5, 60.0) var respawn_delay := 4.0
var health: int

func _ready() -> void:
	health = max_health
	$Respawn.timeout.connect(func() -> void: health = max_health)

func _process(_delta: float) -> void:
	visible = health > 0

func take_hit(damage: int) -> void:
	if health <= 0:
		return
	health = maxi(health - damage, 0)
	if health == 0:
		$Respawn.start(respawn_delay)
