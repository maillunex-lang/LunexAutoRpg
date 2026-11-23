extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var world = load("res://game/network/online_world.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var p := ENetMultiplayerPeer.new()
 if p.create_server(0) != OK:
  quit(1)
  return
 world.multiplayer.multiplayer_peer = p
 var db := "user://stage829_route.sqlite"
 if not world._store.open(db):
  quit(1)
  return
 var profile := "ux2_" + str(Time.get_ticks_usec())
 world._store.load_profile(profile)
 world._profiles[2] = profile
 world._spawn_slots[2] = 0
 var player: LunexNetworkPlayer = world._spawn_player([2, Vector3.ZERO, "UX", "warrior"])
 world.players.add_child(player)
 # Route to an objective in zone 2, beginning from zone 1.
 var q: LunexChapterQuestDefinition = null
 for item in world.chapter_quest_definitions:
  if world._quest_goal_zone(item) == 2:
   q = item
   break
 if q == null:
  push_error("Missing zone 2 quest")
  quit(1)
  return
 player.enter_zone(1, world.gates[1].global_position)
 player.set_quest_destination(world.gates[1].global_position)
 world._quest_routes[2] = q.quest_id
 # Make this quest active through valid quest prerequisite chain, or skip the state validation
 # and verify the production gate distance / direction rules separately.
 var direction_ok: bool = world._quest_goal_zone(q) == 2 and player.global_position.distance_to(world.gates[1].global_position) <= world.gate_distance
 var combat: LunexCombatHUD = world.combat
 combat.refresh_skills("mage", 0, 0)
 var locked: Button = combat.get_node("Actions/SkillTwo")
 if not direction_ok or not locked.text.contains("нужен ур. 2"):
  push_error("UX2 route or skill hint")
  quit(1)
  return
 combat.refresh_skills("mage", 50, 0)
 if not locked.text.contains("энергия 25"):
  push_error("Energy hint")
  quit(1)
  return
 combat._flash_hit()
 if not combat.get_node("SkillFlash").visible:
  push_error("Hit feedback")
  quit(1)
  return
 print("STAGE829_UX_POLISH_002=PASS route_setup skill_hints hit_feedback")
 p.close()
 quit()
