extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var world: Node3D = load("res://game/network/online_world.tscn").instantiate()
 root.add_child(world)
 await process_frame
 await physics_frame
 await physics_frame
 var map := world.get_world_3d().navigation_map
 var ok := true
 for i in range(5):
  var arrival: Vector3 = world.arrivals[i].global_position
  var gate: Vector3 = world.gates[i].global_position
  var route := NavigationServer3D.map_get_path(map, arrival, gate, true)
  print("ZONE_", i, " route_nodes=", route.size(), " start=", arrival, " gate=", gate)
  if route.size() < 2:
   ok = false
 if ok:
  print("STAGE825_NAV_PATHS=PASS")
  quit()
 else:
  push_error("Zone route missing")
  quit(1)
