extends Node3D

@export_range(1.0, 20.0, 0.5) var movement_speed := 7.0
@export var auto_destination := Vector3(0, 0.5, -24)
@export var route_waypoints: PackedVector3Array = PackedVector3Array([Vector3(0, 0.5, -10), Vector3(0, 0.5, -24)])
var _waypoint_index := 0
@onready var actor: CharacterBody3D = $Player
@onready var streamer: SeamlessChunkStreamer = $Chunks
var auto_travel := true

func _physics_process(delta: float) -> void:
	if not auto_travel:
		return
	var destination: Vector3 = route_waypoints[_waypoint_index] if _waypoint_index < route_waypoints.size() else auto_destination
	var remaining := destination - actor.global_position
	remaining.y = 0
	if remaining.length() < 0.2:
		if _waypoint_index < route_waypoints.size():
			_waypoint_index += 1
		else:
			auto_travel = false
		return
	var step := minf(movement_speed * delta, remaining.length())
	actor.global_position += remaining.normalized() * step
	streamer.update_streaming()
