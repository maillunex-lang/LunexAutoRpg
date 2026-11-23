extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var viewport = root.get_viewport().get_visible_rect().size
	var actions: Control = world.combat.get_node("Actions")
	var joystick: Control = world.joystick
	print("VIEWPORT=", viewport, " ACTIONS=", actions.position, " JOYSTICK=", joystick.position)
	if actions.position.x < viewport.x * 0.5 or actions.position.y < 0 or joystick.position.x > viewport.x * 0.5 or joystick.position.y < 0:
		push_error("HUD placement invalid")
		quit(1)
		return
	if joystick.joystick_mode != 1 or joystick.visibility_mode != 2:
		push_error("Floating joystick configuration invalid")
		quit(1)
		return
	print("STAGE824_MOBILE_HUD=PASS")
	quit()
