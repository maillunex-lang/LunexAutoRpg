extends "res://tests/stage02_smoke.gd"
## Run on a fresh test zone with --script tests/stage05_smoke.gd -- HOST PORT.

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return

	var first := _client("First")
	var second := _client("Second")
	var spectator := _client("Spectator")
	var guest := _client("Guest")
	var clients := [first, second, spectator, guest]
	for client in clients:
		_join(client, args[0], args[1].to_int(), client.get_parent().name)
	if not await _expect("four distinct profiles joined the zone", func() -> bool:
		return clients.all(func(client: Node) -> bool:
			return client.players.get_child_count() == 4 and _training(client).get("quest") == 0)
	):
		return

	first.chat.message_requested.emit("  Привет [b]мир[/b]  ")
	first.chat.message_requested.emit("Too soon")
	second.chat.message_requested.emit("Ответ")
	if not await _expect("all clients receive both messages with server names", func() -> bool:
		return clients.all(func(client: Node) -> bool:
			return client.chat.messages.has("First: Привет [b]мир[/b]") and client.chat.messages.has("Second: Ответ"))
	):
		return
	await create_timer(1.05).timeout
	guest.chat.message_requested.emit("x".repeat(205))
	if not await _expect("chat is plain text, bounded and rate limited", func() -> bool:
		return first.chat.messages.size() == 3 and first.chat.messages[2] == "Guest: " + "x".repeat(200) and not first.chat.history.bbcode_enabled
	):
		return

	for client: Node in [first, second, spectator]:
		client.progress_hud.accept_requested.emit()
	if not await _expect("three profiles accept the quest; guest remains unassigned", func() -> bool:
		return _training(first).get("quest") == 1 and _training(second).get("quest") == 1 and _training(spectator).get("quest") == 1 and _training(guest).get("quest") == 0
	):
		return

	if not await _hit(first, 40) or not await _return_to_spawn(first, spectator, args):
		return
	if not await _hit(second, 20) or not await _return_to_spawn(second, spectator, args):
		return
	if not await _hit(guest, 0):
		return
	if not await _expect("both contributors earn a reward; spectator and last hitter are ineligible", func() -> bool:
		return _awarded(first) and _awarded(second) and _training(spectator).get("experience") == 0 and _training(guest).get("experience") == 0
	):
		return

	if not await _return_to_spawn(guest, spectator, args):
		return
	if not await _expect("target respawns for another encounter", func() -> bool: return first.enemy.health == 60):
		return

	second.combat.auto_requested.emit(true)
	if not await _expect("victory can be repeated after respawn", func() -> bool: return first.enemy.health == 0):
		return
	first.screen.disconnect_requested.emit()
	if not await _expect("disconnect clears chat and removes the player", func() -> bool:
		return first.chat.messages.is_empty() and second.players.get_child_count() == 3
	):
		return
	_join(first, args[0], args[1].to_int(), "First")
	if not await _expect("reconnect keeps one award per profile and starts a fresh chat", func() -> bool:
		return _awarded(first) and _awarded(second) and first.chat.messages.is_empty() and _training(spectator).experience == 0 and _training(guest).experience == 0
	):
		return

	for client in clients:
		client.screen.disconnect_requested.emit()
	quit()

func _hit(client: Node, health_after: int) -> bool:
	client.combat.selected = true
	client.combat.auto_requested.emit(true)
	if not await _expect("server confirms hit from " + str(client.get_parent().name), func() -> bool:
		return client.enemy.health == health_after
	):
		return false
	client.combat.auto_requested.emit(false)
	return true

func _return_to_spawn(client: Node, observer: Node, args: PackedStringArray) -> bool:
	var disconnected_id := str(client.multiplayer.get_unique_id())
	client.screen.disconnect_requested.emit()
	if not await _expect("departing fighter leaves the approach clear", func() -> bool:
		return observer.players.get_child_count() == 3 and not observer.players.has_node(disconnected_id)
	):
		return false
	_join(client, args[0], args[1].to_int(), client.get_parent().name)
	return await _expect("fighter reenters the same fight from spawn", func() -> bool:
		return client.players.get_child_count() == 4 and observer.players.get_child_count() == 4
	)

func _awarded(client: Node) -> bool:
	var state: Dictionary = _training(client)
	return state.get("quest", -1) == 2 and state.experience == 25 and state.item == "training_ring"
