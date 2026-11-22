extends "res://tests/stage02_smoke.gd"
## Run with two clients on a clean arena and optional saved test profile.

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return
	var fighter := _client("Fighter")
	var observer := _client("Observer")
	var saved_token := OS.get_environment("LUNEX_TEST_FIRST")
	if not saved_token.is_empty():
		fighter._profile_token = saved_token
	_join(fighter, args[0], args[1].to_int(), "Fighter")
	_join(observer, args[0], args[1].to_int(), "Observer")
	if not await _expect("two clients see the hero and its health", func() -> bool:
		return fighter.players.get_child_count() == 2 and observer.players.get_child_count() == 2 and not fighter._progress.is_empty()
	):
		return
	var fighter_id := str(fighter.multiplayer.get_unique_id())
	var hero := fighter.players.get_node(fighter_id) as LunexNetworkPlayer
	var remote := observer.players.get_node(fighter_id) as LunexNetworkPlayer
	var original: Dictionary = fighter._progress.duplicate(true)
	fighter.combat.target_index = 1
	fighter.combat.selected = true
	fighter.combat.auto_requested.emit(true)
	if not await _expect("both clients see the guard windup", func() -> bool:
		return fighter.watch.telegraph_active and observer.watch.telegraph_active and observer.watch.warning.visible
	):
		return
	var offset: Vector3 = hero.position - fighter.watch.position
	fighter.joystick.output = Vector2(offset.x, offset.z).normalized()
	if not await _expect("the guard attack misses a player who dodged", func() -> bool:
		return fighter.watch.counter_sequence == 1 and hero.health == 100 and remote.health == 100
	):
		return
	fighter.joystick.output = Vector2.ZERO
	await create_timer(0.2).timeout
	fighter.combat.auto_requested.emit(true)
	if not await _expect("fighter returns to the guard's radius", func() -> bool:
		return hero.position.distance_to(fighter.watch.position) < 1.65
	):
		return
	fighter.combat.auto_requested.emit(false)
	for hp in [80, 60, 40, 20, 0]:
		if not await _expect("both clients observe hero health " + str(hp), func() -> bool:
			return hero.health == hp and remote.health == hp
		):
			return

	var down_position := hero.server_position
	var guard_health: int = fighter.watch.health
	fighter.joystick.output = Vector2.DOWN
	fighter.combat.auto_requested.emit(true)
	fighter.combat.attack_requested.emit()
	await create_timer(0.5).timeout
	if not await _expect("fallen hero cannot move or attack and both see the fall", func() -> bool:
		return hero.server_position.is_equal_approx(down_position) and not hero.auto_enabled and fighter.watch.health == guard_health 			and hero.hero_visual.clips.assigned_animation == hero.hero_visual.defeat_clip 			and remote.hero_visual.clips.assigned_animation == remote.hero_visual.defeat_clip
	):
		return
	fighter.joystick.output = Vector2.ZERO
	if await _expect("hero returns to spawn healthy, auto off, progress intact", func() -> bool:
		return hero.health == 100 and remote.health == 100 and hero.position.distance_to(hero._spawn_position) < 0.3 			and not hero.auto_enabled and fighter._progress == original
	):
		quit()
