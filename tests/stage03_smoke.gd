extends "res://tests/stage02_smoke.gd"
## Run against a clean stage 3 server with --script tests/stage03_smoke.gd -- HOST PORT.

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return
	var first := _client("First")
	var second := _client("Second")
	var port := args[1].to_int()
	_join(first, args[0], port, "Fighter")
	_join(second, args[0], port, "Observer")
	if not await _expect("two combat clients connected", func() -> bool:
		return first.players.get_child_count() == 2 and second.players.get_child_count() == 2
	):
		return
	var player := first.players.get_node(str(first.multiplayer.get_unique_id())) as LunexNetworkPlayer
	var health: int = first.enemy.max_health
	first.combat.selected = true
	first.combat.attack_requested.emit()
	await create_timer(0.3).timeout
	if not await _expect("out-of-range attack was rejected", func() -> bool:
		return first.enemy.health == health and second.enemy.health == health
	):
		return

	first.joystick.output = Vector2.DOWN
	if not await _expect("fighter moves clear of the other spawn", func() -> bool: return player.position.z > 1.5):
		return
	first.joystick.output = Vector2(signf(-player.position.x), 0)
	if not await _expect("fighter lines up behind the obstacle", func() -> bool: return absf(player.position.x) < 0.35):
		return
	first.joystick.output = Vector2.ZERO
	await create_timer(0.25).timeout
	first.combat.auto_requested.emit(true)
	if not await _expect("auto starts", func() -> bool: return player.auto_enabled):
		return
	first.combat.auto_requested.emit(false)
	if not await _expect("stop button turns auto off", func() -> bool: return not player.auto_enabled):
		return
	first.combat.auto_requested.emit(true)
	if not await _expect("auto restarts", func() -> bool: return player.auto_enabled):
		return
	first.joystick.output = Vector2.RIGHT
	if not await _expect("manual movement overrides auto", func() -> bool: return not player.auto_enabled):
		return
	first.joystick.output = Vector2.ZERO
	await create_timer(0.2).timeout

	first.combat.auto_requested.emit(true)
	if not await _expect("auto steers around the obstructed path", func() -> bool:
		return player.position.z < -2.7 and absf(player.position.x) > 1.6
	):
		return
	if not await _expect("both clients see damage after the approach", func() -> bool:
		return first.enemy.health == health - 20 and second.enemy.health == health - 20
	):
		return
	first.combat.auto_requested.emit(false)
	first.combat.attack_requested.emit()
	await create_timer(0.2).timeout
	if not await _expect("manual attack shares the auto cooldown", func() -> bool:
		return first.enemy.health == health - 20 and second.enemy.health == health - 20
	):
		return
	await create_timer(0.8).timeout
	first.combat.attack_requested.emit()
	if not await _expect("manual attack works at close range", func() -> bool:
		return first.enemy.health == health - 40 and second.enemy.health == health - 40
	):
		return
	first.combat.auto_requested.emit(true)
	if not await _expect("victory stops auto and is shared", func() -> bool:
		return first.enemy.health == 0 and second.enemy.health == 0 and not player.auto_enabled
	):
		return
	if not await _expect("enemy respawns for both clients", func() -> bool:
		return first.enemy.health == health and second.enemy.health == health
	):
		return
	first.screen.disconnect_requested.emit()
	second.screen.disconnect_requested.emit()
	quit()
