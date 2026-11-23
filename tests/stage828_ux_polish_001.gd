extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var screen: LunexConnectScreen = load("res://game/network/connect_screen.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 if screen.address_field.text != "78.17.214.93" or int(screen.port_field.value) != 28801:
  push_error("Wrong default endpoint")
  quit(1)
  return
 var combat: LunexCombatHUD = load("res://game/combat/combat_hud.tscn").instantiate()
 root.add_child(combat)
 await process_frame
 var world = load("res://game/network/online_world.tscn").instantiate()
 root.add_child(world)
 await process_frame
 combat.targets = world.targets
 combat.enter_zone(0, 0)
 var calls := [0]
 combat.attack_requested.connect(func() -> void: calls[0] += 1)
 combat._attack_pressed()
 if not combat.selected or calls[0] != 1:
  push_error("Attack did not select living target")
  quit(1)
  return
 var a: Control = world.combat.get_node("Actions")
 if a.position.y < 0 or a.position.y + 376.0 * a.scale.y > root.get_viewport().get_visible_rect().size.y + 1.0:
  push_error("HUD extends outside viewport")
  quit(1)
  return
 print("STAGE828_UX_POLISH_001=PASS")
 quit()
