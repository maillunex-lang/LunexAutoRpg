extends SceneTree
func _initialize() -> void:
	var source := FileAccess.get_file_as_string("res://game/network/online_world.gd")
	var start := source.find("func _request_quest_route(")
	var stop := source.find("func _quest_route_notice(", start)
	if start < 0 or stop < 0:
		push_error("Quest route handler not found")
		quit(1)
		return
	var route := source.substr(start, stop - start)
	if route.contains("gate.global_position") or route.contains("enter_zone(") or route.contains("_arrive.rpc_id("):
		push_error("Quest routing still targets gate or teleports")
		quit(1)
		return
	if not route.contains("set_quest_destination(giver.global_position)") or not route.contains("set_quest_destination(target.global_position)") or not route.contains("set_quest_destination(npc.global_position)"):
		push_error("Quest routing objective destinations missing")
		quit(1)
		return
	print("MAIN_WORLD_QUEST_ROUTE=PASS full_objective_destinations=true no_gate_stop=true no_teleport=true")
	quit(0)
