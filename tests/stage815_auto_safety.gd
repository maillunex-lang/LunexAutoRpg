extends SceneTree
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var cases := [
		[true,false,false,true,true],
		[false,false,false,true,false],
		[true,true,false,true,false],
		[true,false,true,true,false],
		[true,false,false,false,false]
	]
	for c in cases:
		if LunexAutoSafety.allow_auto(c[0],c[1],c[2],c[3]) != c[4]:
			push_error("AUTO_SAFETY_FAIL")
			quit(1)
			return
	var world := load("res://game/network/online_world.tscn") as PackedScene
	if world == null:
		quit(1)
		return
	print("STAGE815_SAFETY_TOTAL=", cases.size() + 1)
	quit()
