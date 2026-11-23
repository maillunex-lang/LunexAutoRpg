class_name LunexTapNavigation
extends RefCounted

const ARRIVAL_RADIUS := 0.45
const MANUAL_DEADZONE := 0.12

static func input_direction(origin: Vector3, destination: Vector3, manual_input: Vector2) -> Vector2:
	if manual_input.length() > MANUAL_DEADZONE:
		return Vector2.ZERO
	var delta := Vector2(destination.x - origin.x, destination.z - origin.z)
	if delta.length() <= ARRIVAL_RADIUS:
		return Vector2.ZERO
	return delta.normalized()

static func should_cancel_for_manual(manual_input: Vector2) -> bool:
	return manual_input.length() > MANUAL_DEADZONE

static func valid_route(path: PackedVector3Array, destination: Vector3, max_end_error: float = 2.0) -> bool:
	return path.size() >= 2 and path[path.size() - 1].distance_to(destination) <= max_end_error

static func route_direction(origin: Vector3, destination: Vector3, path: PackedVector3Array, manual_input: Vector2) -> Vector2:
	if should_cancel_for_manual(manual_input) or origin.distance_to(destination) <= ARRIVAL_RADIUS:
		return Vector2.ZERO
	if not valid_route(path, destination):
		return Vector2.ZERO
	var i := 1
	while i < path.size() - 1 and origin.distance_to(path[i]) <= ARRIVAL_RADIUS:
		i += 1
	return input_direction(origin, path[i], manual_input)
