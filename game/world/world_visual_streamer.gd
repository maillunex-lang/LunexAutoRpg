class_name LunexWorldVisualStreamer
extends Node3D

## Visual-only streaming for the main game's world. Never unload server physics/navmesh.
@export var enabled_on_server := false
@export_range(20.0, 500.0, 1.0) var view_distance := 95.0
@export var observer_path: NodePath
@export var visual_groups: Array[NodePath] = []

func _ready() -> void:
	set_process(not multiplayer.is_server() or enabled_on_server)

func _process(_delta: float) -> void:
	var observer := get_node_or_null(observer_path) as Node3D
	if observer == null:
		return
	for path in visual_groups:
		var group := get_node_or_null(path) as Node3D
		if group == null:
			continue
		# Keep authoritative collisions, NavigationRegion3D and AI untouched.
		group.visible = group.global_position.distance_to(observer.global_position) <= view_distance
