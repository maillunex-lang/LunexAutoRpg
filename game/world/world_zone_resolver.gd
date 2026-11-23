class_name LunexWorldZoneResolver
extends RefCounted

const CENTERS := [0.0, 42.0, 84.0, 126.0, 168.0]
const HALF_SPACING := 21.0

static func zone_at_x(world_x: float) -> int:
	return clampi(int(floor((world_x + HALF_SPACING) / 42.0)), 0, CENTERS.size() - 1)

static func is_adjacent(from_zone: int, to_zone: int) -> bool:
	return from_zone >= 0 and to_zone >= 0 and from_zone < CENTERS.size() and to_zone < CENTERS.size() and absi(to_zone - from_zone) == 1

static func is_valid_crossing(from_zone: int, to_zone: int, world_x: float, gate_watch_complete: bool) -> bool:
	if not is_adjacent(from_zone, to_zone):
		return false
	if from_zone == 0 and to_zone == 1 and not gate_watch_complete:
		return false
	var boundary: float = (CENTERS[mini(from_zone, to_zone)] + CENTERS[maxi(from_zone, to_zone)]) * 0.5
	return absf(world_x - boundary) <= 4.0
