extends SceneTree
var count := 0
func check(condition: bool, label: String) -> void:
	if not condition:
		push_error("FAIL " + label)
		quit(1)
		return
	count += 1
	print("PASS ", label)
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	check(LunexTapNavigation.input_direction(Vector3.ZERO, Vector3(10,0,0), Vector2.ZERO).is_equal_approx(Vector2.RIGHT), "Tap direction")
	check(LunexTapNavigation.input_direction(Vector3.ZERO, Vector3(0.1,0,0), Vector2.ZERO) == Vector2.ZERO, "Arrival radius")
	check(LunexTapNavigation.input_direction(Vector3.ZERO, Vector3(10,0,0), Vector2.RIGHT) == Vector2.ZERO, "Manual priority")
	check(LunexTapNavigation.should_cancel_for_manual(Vector2(0.5,0)), "Manual cancels tap")
	check(not LunexTapNavigation.should_cancel_for_manual(Vector2(0.02,0)), "Deadzone")
	var scene := load("res://game/network/online_world.tscn") as PackedScene
	check(scene != null, "World scene loads")
	var route := PackedVector3Array([Vector3.ZERO, Vector3(1, 0, 0), Vector3(5, 0, 0)])
	check(LunexTapNavigation.valid_route(route, Vector3(5,0,0)), "Valid route reaches destination")
	check(not LunexTapNavigation.valid_route(route, Vector3(50,0,0)), "Reject route ending away from destination")
	check(LunexTapNavigation.route_direction(Vector3(0.9,0,0), Vector3(5,0,0), route, Vector2.ZERO).x > 0.9, "Skip already reached waypoint")
	check(LunexTapNavigation.route_direction(Vector3(4.9,0,0), Vector3(5,0,0), route, Vector2.ZERO) == Vector2.ZERO, "Stop at final destination")
	check(LunexTapNavigation.route_direction(Vector3.ZERO, Vector3(5,0,0), route, Vector2.RIGHT) == Vector2.ZERO, "Manual override blocks route")
	print("STAGE815_TAP_TOTAL=", count)
	quit()
