class_name LunexStreamedDecor
extends Node3D

## Optional visual-only chunk instances. Collision, NPCs and navigation stay persistent.
@export var chunk_scenes: Array[PackedScene] = []
@export var chunk_centers: PackedVector3Array = PackedVector3Array()
@export_range(15.0, 500.0, 1.0) var load_radius := 85.0
@export_range(5.0, 150.0, 1.0) var hysteresis := 25.0
var _loaded: Dictionary = {}

func update_for_position(observer_position: Vector3) -> void:
	for i in range(mini(chunk_scenes.size(), chunk_centers.size())):
		var distance := observer_position.distance_to(chunk_centers[i])
		if not _loaded.has(i) and distance <= load_radius and chunk_scenes[i] != null:
			var instance := chunk_scenes[i].instantiate() as Node3D
			if instance == null:
				continue
			add_child(instance)
			instance.position = chunk_centers[i]
			_loaded[i] = instance
		elif _loaded.has(i) and distance > load_radius + hysteresis:
			(_loaded[i] as Node).queue_free()
			_loaded.erase(i)

func loaded_count() -> int:
	return _loaded.size()

func clear_chunks() -> void:
	for chunk in _loaded.values():
		(chunk as Node).queue_free()
	_loaded.clear()
