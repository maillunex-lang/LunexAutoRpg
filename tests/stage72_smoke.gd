extends "res://tests/stage06_smoke.gd"
## Use profiles that finished and equipped the tutorial on the previous build.

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		quit(2)
		return
	var first := _client("First")
	var second := _client("Second")
	for client in [first, second]:
		var token := OS.get_environment("LUNEX_TEST_" + str(client.get_parent().name).to_upper())
		if token.length() != 64:
			quit(2)
			return
		client._profile_token = token
		_join(client, args[0], args[1].to_int(), client.get_parent().name)
	if args[2] == "reload":
		if await _expect("both slots and level two survive a server restart", func() -> bool:
			return _chapter_complete(first) and _chapter_complete(second)
		):
			quit()
		return
	if not await _expect("legacy tutorial experience and equipped rings were migrated", func() -> bool:
		return _equipped(first) and _equipped(second)
	):
		return

	var fresh := _client("Fresh")
	_join(fresh, args[0], args[1].to_int(), "Fresh")
	if not await _expect("fresh profile arrives", func() -> bool:
		return _training(fresh).get("quest") == 0
	):
		return
	fresh.progress_hud.selected_quest = 1
	fresh.progress_hud.accept_requested.emit()
	await create_timer(0.3).timeout
	if not await _expect("server rejects the locked watch quest", func() -> bool:
		return _watch_quest(fresh).is_empty()
	):
		return
	fresh.screen.disconnect_requested.emit()
	if not await _expect("temporary profile leaves", func() -> bool: return first.players.get_child_count() == 2):
		return

	for client in [first, second]:
		client.progress_hud.selected_quest = 1
		client.progress_hud.accept_requested.emit()
	if not await _expect("watch quest is available and accepted after training", func() -> bool:
		return _watch_quest(first).get("quest") == 1 and _watch_quest(second).get("quest") == 1
	):
		return
	first.combat.get_node("%Target").pressed.emit()
	first.combat.auto_requested.emit(true)
	if not await _expect("training victory leaves watch progress and health untouched", func() -> bool:
		return first.enemy.health == 0 and first.watch.health == 90 and _watch_quest(first).get("quest") == 1
	):
		return
	first.combat.get_node("%Target").pressed.emit()
	if not await _expect("target button selects the living watch guard", func() -> bool:
		return first.combat.target_index == 1
	):
		return
	first.combat.auto_requested.emit(true)
	if not await _expect("auto navigates to the selected guard and hits it", func() -> bool:
		return first.watch.health == 70 and second.watch.health == 70
	):
		return
	first.screen.disconnect_requested.emit()
	if not await _expect("first contributor can reconnect during the watch fight", func() -> bool:
		return second.players.get_child_count() == 1
	):
		return
	_join(first, args[0], args[1].to_int(), "First")
	if not await _expect("both are back in the zone", func() -> bool: return first.players.get_child_count() == 2):
		return
	second.combat.target_index = 1
	second.combat.selected = true
	second.combat.auto_requested.emit(true)
	if not await _expect("both contributors get the watch reward and reach 50 experience", func() -> bool:
		return _watch_quest(first).get("item") == "watch_medallion" and _watch_quest(second).get("item") == "watch_medallion" and first._progress.experience == 50 and second._progress.experience == 50
	):
		return
	for client in [first, second]:
		client.progress_hud.selected_quest = 1
		client.progress_hud.equip_requested.emit()
	if await _expect("ring and medallion occupy separate slots", func() -> bool:
		return _chapter_complete(first) and _chapter_complete(second)
	):
		quit()

func _watch_quest(client: Node) -> Dictionary:
	return client._progress.get("quests", {}).get("gate_watch", {})

func _chapter_complete(client: Node) -> bool:
	var watch := _watch_quest(client)
	return _training(client).get("equipped") == "training_ring" and watch.get("quest") == 2 and watch.get("equipped") == "watch_medallion" and client._progress.experience == 50
