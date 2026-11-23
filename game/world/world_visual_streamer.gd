class_name LunexWorldVisualStreamer
extends Node3D

## Client-side visual culling only. Never frees world nodes or server collision/navmesh.
@export_range(20.0, 500.0, 1.0) var view_distance := 95.0
@export var visual_groups: Array[NodePath] = []

func update_for_position(observer_position: Vector3) -> void:
	for path in visual_groups:
		var group := get_node_or_null(path) as Node3D
		if group == null:
			continue
		group.visible = group.global_position.distance_to(observer_position) <= view_distance

func show_all() -> void:
	for path in visual_groups:
		var group := get_node_or_null(path) as Node3D
		if group != null:
			group.visible = true
