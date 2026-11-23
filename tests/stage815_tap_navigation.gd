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
	print("STAGE815_TAP_TOTAL=", count)
	quit()
