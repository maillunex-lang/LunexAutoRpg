extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var world = load("res://game/network/online_world.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var joy: Control = world.joystick
 var rect := root.get_viewport().get_visible_rect()
 var left := Vector2(rect.size.x * 0.3, rect.size.y * 0.5)
 var right := Vector2(rect.size.x * 0.7, rect.size.y * 0.5)
 if not joy._is_point_inside_joystick_area(left) or joy._is_point_inside_joystick_area(right):
  push_error("Floating joystick touch area broken")
  quit(1)
  return
 var combat: LunexCombatHUD = load("res://game/combat/combat_hud.tscn").instantiate()
 root.add_child(combat)
 await process_frame
 combat.targets = world.targets
 combat.enter_zone(0, 0)
 combat._cycle_target()
 if not combat.selected:
  push_error("Combat target selection failed")
  quit(1)
  return
 var attack_count := [0]
 combat.attack_requested.connect(func() -> void: attack_count[0] += 1)
 combat.get_node("Actions/Attack").emit_signal("pressed")
 if attack_count[0] != 1:
  push_error("Attack signal not connected")
  quit(1)
  return
 print("STAGE827_JOYSTICK_COMBAT=PASS")
 quit()
