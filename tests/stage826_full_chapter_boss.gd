extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func fail(message: String) -> void:
 push_error("STAGE826_FAIL: " + message)
 quit(1)

func run() -> void:
 var world = load("res://game/network/online_world.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var peer := ENetMultiplayerPeer.new()
 if peer.create_server(0) != OK:
  fail("ENet server init")
  return
 world.multiplayer.multiplayer_peer = peer
 var db_path := "user://stage826_full_chapter_boss.sqlite"
 if not world._store.open(db_path):
  fail("SQLite open")
  return
 var profile := "full_chapter_" + str(Time.get_ticks_usec())
 if world._store.load_profile(profile).is_empty():
  fail("Profile create")
  return
 world._profiles[2] = profile
 var player: LunexNetworkPlayer = world._spawn_player([2, Vector3(0, 0.1, 0), "Integration", "warrior"])
 world.players.add_child(player)
 for target in world.targets:
  target.hit_landed.connect(world._record_hit.bind(target.target_id))
  target.defeated.connect(world._reward_contributors.bind(target.target_id))
 var count := 0
 for q in world.chapter_quest_definitions:
  var giver: LunexNpcActor = null
  for npc in world.npcs.get_children():
   if npc.npc_id == q.npc_id:
    giver = npc
    break
  if giver == null:
   fail("Missing giver " + q.quest_id)
   return
  player.enter_zone(giver.zone_id, giver.global_position)
  if not world._npc_near_player(player, q.npc_id):
   fail("NPC not reachable " + q.quest_id)
   return
  if not world._store.chapter_accept(profile, q.quest_id, q.prerequisite_id):
   fail("Quest acceptance " + q.quest_id)
   return
  if not q.objective_enemy_id.is_empty():
   var target: LunexTrainingEnemy = null
   for candidate in world.targets:
    if candidate.target_id == q.objective_enemy_id:
     target = candidate
     break
   if target == null:
    fail("Enemy not found " + q.quest_id)
    return
   player.enter_zone(target.zone_id, target.global_position + Vector3(0, 0, 1.5))
   world._record_hit(2, target.target_id)
   target.take_hit(target.max_health, 2)
   if target.health != 0:
    fail("Enemy survived " + q.quest_id)
    return
  else:
   var objective: LunexNpcActor = null
   for npc in world.npcs.get_children():
    if npc.npc_id == q.objective_npc_id:
     objective = npc
     break
   if objective == null:
    fail("Objective NPC missing " + q.quest_id)
    return
   player.enter_zone(objective.zone_id, objective.global_position)
   if not world._npc_near_player(player, q.objective_npc_id):
    fail("Objective NPC unreachable " + q.quest_id)
    return
   world._chapter_npc_objective(2, q.objective_npc_id)
  var progress: Dictionary = world._store.read_profile(profile).get("chapter_quests", {})
  if not progress.has(q.quest_id) or int(progress[q.quest_id].state) != LunexProgressStore.Quest.COMPLETE:
   fail("Quest not completed " + q.quest_id)
   return
  count += 1
  print("CHAPTER_COMPLETE ", count, "/11 ", q.quest_id)
 var state: Dictionary = world._store.read_profile(profile)
 if state.chapter_quests.size() != 11 or state.experience <= 0:
  fail("Persistent rewards")
  return
 print("STAGE826_FULL_CHAPTER_BOSS=PASS quests=", count, " experience=", state.experience, " inventory=", state.inventory.size())
 peer.close()
 quit()
