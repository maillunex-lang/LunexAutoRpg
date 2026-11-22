class_name LunexHeroVisual
extends Node3D

@export var idle_clip: StringName = &"Idle"
@export var run_clip: StringName = &"Running_A"
@export var attack_clip: StringName = &"1H_Melee_Attack_Slice_Diagonal"

@onready var clips: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	clips.get_animation(idle_clip).loop_mode = Animation.LOOP_LINEAR
	clips.get_animation(run_clip).loop_mode = Animation.LOOP_LINEAR

func show_motion(moving: bool) -> void:
	if clips.is_playing() and clips.current_animation == attack_clip:
		return
	var next := run_clip if moving else idle_clip
	if clips.current_animation != next:
		clips.play(next, 0.12)

func show_attack() -> void:
	clips.stop()
	clips.play(attack_clip, 0.04)
