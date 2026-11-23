class_name SeamlessChunkStreamer
extends Node3D

## Isolated demonstration: native editable chunk scenes, not the live ENet world.
@export var start_chunk: PackedScene
@export var grove_chunk: PackedScene
@export_range(8.0, 200.0, 1.0) var chunk_width := 24.0
@export_range(0, 2, 1) var preload_radius := 1
@export_node_path("Node3D") var tracked_actor_path: NodePath = NodePath("../Player")
@onready var tracked_actor: Node3D = get_node_or_null(tracked_actor_path) as Node3D

var _loaded: Dictionary = {}

func _ready() -> void:
	update_streaming()

func update_streaming() -> void:
	if tracked_actor == null:
		return
	var current := _index_for_position(tracked_actor.global_position)
	for index in range(2):
		var wanted: bool = abs(index - current) <= preload_radius
		if wanted and not _loaded.has(index):
			var scene := start_chunk if index == 0 else grove_chunk
			if scene == null:
				continue
			var chunk := scene.instantiate()
			add_child(chunk)
			chunk.position = Vector3(0, 0, -float(index) * chunk_width)
			_loaded[index] = chunk
		elif not wanted and _loaded.has(index):
			_loaded[index].queue_free()
			_loaded.erase(index)

func _index_for_position(world_position: Vector3) -> int:
	return clampi(int(floor((-world_position.z + chunk_width / 2.0) / chunk_width)), 0, 1)

func loaded_count() -> int:
	return _loaded.size()

func loaded_indices() -> Array:
	return _loaded.keys()
