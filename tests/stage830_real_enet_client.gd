extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var world = load("res://game/network/online_world.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var smoke_port := 28991
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--smoke-port="):
   smoke_port = int(arg.trim_prefix("--smoke-port="))
 world._connect_client("127.0.0.1", smoke_port, "GameplaySmoke")
 var joined := false
 for i in range(240):
  await process_frame
  if is_instance_valid(world._local_player) and not world._progress.is_empty():
   joined = true
   break
 if not joined:
  push_error("ENET_SMOKE: no real server join/progress; status=" + world.screen.status.text)
  quit(1)
  return
 print("ENET_SMOKE_JOIN=PASS peer=", world.multiplayer.get_unique_id(), " player=", world._local_player.display_name)
 world._request_attack.rpc_id(1, 0)
 for i in range(30):
  await process_frame
 if not world.combat.get_node("Actions/SkillNotice").text.contains("Подойди ближе"):
  push_error("ENET_SMOKE: missing out-of-range explanation")
  quit(1)
  return
 print("ENET_SMOKE_RANGE_FEEDBACK=PASS")
 world._choose_class.rpc_id(1,"warrior")
 for i in range(40):
  await process_frame
 var before: int = world.enemy.health
 world._request_auto.rpc_id(1, true, 0)
 for i in range(600):
  await process_frame
  if world.enemy.health < before:
   break
 print("ENET_SMOKE_ATTACK before=",before," after=",world.enemy.health)
 if world.enemy.health >= before:
  push_error("ENET_SMOKE: attack failed")
  quit(1)
  return
 world._request_auto.rpc_id(1, false, 0)
 var energy_before: float = world._local_player.ability_energy
 world._request_skill.rpc_id(1, "warrior_strike", 0)
 for i in range(100):
  await process_frame
 print("ENET_SMOKE_SKILL energy_before=", energy_before, " energy_after=", world._local_player.ability_energy)
 if world._local_player.ability_energy >= energy_before:
  push_error("ENET_SMOKE: skill did not consume energy")
  quit(1)
  return
 print("ENET_SMOKE=PASS")
 quit()
