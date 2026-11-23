extends SceneTree
func _initialize() -> void:
	assert(LunexWorldZoneResolver.zone_at_x(0) == 0)
	assert(LunexWorldZoneResolver.zone_at_x(21.1) == 1)
	assert(LunexWorldZoneResolver.zone_at_x(62.9) == 1)
	assert(LunexWorldZoneResolver.zone_at_x(63.1) == 2)
	assert(LunexWorldZoneResolver.zone_at_x(168) == 4)
	assert(not LunexWorldZoneResolver.is_valid_crossing(0, 1, 21.1, false))
	assert(LunexWorldZoneResolver.is_valid_crossing(0, 1, 21.1, true))
	assert(LunexWorldZoneResolver.is_valid_crossing(1, 0, 20.9, false))
	assert(not LunexWorldZoneResolver.is_valid_crossing(0, 2, 42, true))
	assert(not LunexWorldZoneResolver.is_valid_crossing(1, 2, 100, true))
	print("MAIN_WORLD_ZONE_RESOLVER=PASS boundaries=true adjacency=true progression_guard=true")
	quit(0)
