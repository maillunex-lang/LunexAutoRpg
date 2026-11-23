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
