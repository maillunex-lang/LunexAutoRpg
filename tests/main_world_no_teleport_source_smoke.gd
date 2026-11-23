extends SceneTree
func _initialize() -> void:
	var file := FileAccess.open("res://game/network/online_world.gd", FileAccess.READ)
	assert(file != null)
	var source := file.get_as_text()
	var quest := source.get_slice("func _advance_quest_routes() -> void:", 1).get_slice("func _request_quest_route(", 0)
	var travel := source.get_slice("func _request_travel(previous_zone: int) -> void:", 1).get_slice("func _travel_notice(", 0)
	assert(not quest.contains("enter_zone(") and not quest.contains("_arrive.rpc_id("), "quest routing still teleports")
	assert(not travel.contains("enter_zone(") and not travel.contains("_arrive.rpc_id("), "gate travel still teleports")
	assert(source.contains("player.global_position.x = 20.5"), "locked boundary physical guard missing")
	print("MAIN_WORLD_NO_TELEPORT_SOURCE=PASS quest_no_teleport=true gate_no_teleport=true boundary_guard=true")
	quit(0)
