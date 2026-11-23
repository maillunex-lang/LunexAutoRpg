extends "res://tests/stage02_smoke.gd"
## Run with LUNEX_TEST_FIRST and LUNEX_TEST_SECOND for profiles that completed gate_watch.

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or args.size() > 3:
		quit(2)
		return
	var address := args[0]
	var port := args[1].to_int()
	var first := _client("First")
	var second := _client("Second")
	var locked := _client("Locked")
	for client in [first, second]:
		var token := OS.get_environment("LUNEX_TEST_" + str(client.get_parent().name).to_upper())
		if token.length() != 64 or not token.is_valid_hex_number():
			push_error("Run tests/run_stage75.sh to seed two eligible profiles.")
			quit(2)
			return
		client._profile_token = token
	for client in [first, second, locked]:
		_join(client, address, port, client.get_parent().name)
	if args.size() == 3 and args[2] == "reload":
		if await _expect("both profiles keep access, slots and exactly 75 experience after restart", func() -> bool:
			return _saved_chapter(first) and _saved_chapter(second)
		):
			quit()
		return
	if not await _expect("three clients see one another in the courtyard", func() -> bool:
		return first.players.get_child_count() == 3 and second.players.get_child_count() == 3 and locked.players.get_child_count() == 3
	):
		return

	first.zone_hud.travel_requested.emit()
	if not await _expect("server rejects a request sent far from the gate", func() -> bool:
		return first.zone_hud.notice.visible and first.zone_hud.notice.text.contains("ближе")
	):
		return
	if not await _walk_to_gate(first):
		return
	first.zone_hud.travel_requested.emit()
	first.zone_hud.travel_requested.emit()
	if not await _expect("first enters the passage and stops seeing courtyard players", func() -> bool:
		return first.combat.zone_id == 1 and first.players.get_child_count() == 1 and second.players.get_child_count() == 2
	):
		return

	if not await _walk_to_gate(locked):
		return
	locked.zone_hud.travel_requested.emit()
	if not await _expect("a locked profile sees the prerequisite at the gate", func() -> bool:
		return locked.combat.zone_id == 0 and locked.zone_hud.notice.visible and locked.zone_hud.notice.text.contains("Дозор")
	):
		return
	locked.joystick.output = Vector2.RIGHT
	await create_timer(0.75).timeout
	locked.joystick.output = Vector2.ZERO
	if not await _walk_to_gate(second):
		return
	second.zone_hud.travel_requested.emit()
	if not await _expect("second joins the passage and both see each other again", func() -> bool:
		return second.combat.zone_id == 1 and first.players.get_child_count() == 2 and second.players.get_child_count() == 2 and locked.players.get_child_count() == 1
	):
		return

	first.chat.message_requested.emit("Проход")
	locked.chat.message_requested.emit("Двор")
	if not await _expect("chat reaches only the players in the matching zone", func() -> bool:
		return second.chat.messages.has("First: Проход") and locked.chat.messages.has("Locked: Двор") and not first.chat.messages.has("Locked: Двор") and not locked.chat.messages.has("First: Проход")
	):
		return
	locked.combat.target_index = 2
	locked.combat.auto_requested.emit(true)
	await create_timer(0.25).timeout
	if _hero(locked).auto_enabled:
		push_error("Cross-zone target request was accepted.")
		quit(1)
		return

	for client in [first, second]:
		client.progress_hud.selected_quest = 2
		client.progress_hud.accept_requested.emit()
	if not await _expect("both accept the passage quest", func() -> bool:
		return _quest(first).get("quest") == 1 and _quest(second).get("quest") == 1
	):
		return
	first.combat.get_node("%Target").pressed.emit()
	first.combat.auto_requested.emit(true)
	if not await _expect("auto navigates through the passage to the guard", func() -> bool:
		return first.stone_guard.health == 80 and second.stone_guard.health == 80 and locked.stone_guard.health == 100
	):
		return
	first.combat.auto_requested.emit(false)
	first.screen.disconnect_requested.emit()
	if not await _expect("departed contributor is removed from the passage", func() -> bool: return second.players.get_child_count() == 1):
		return
	_join(first, address, port, "First")
	if not await _expect("reconnect returns to the courtyard and preserves quest progress", func() -> bool:
		return first.combat.zone_id == 0 and first.players.get_child_count() == 2 and _quest(first).get("quest") == 1
	):
		return

	second.combat.get_node("%Target").pressed.emit()
	second.combat.auto_requested.emit(true)
	if not await _expect("guard victory grants the online contributor 25 experience", func() -> bool:
		return _quest(second).get("quest") == 2 and second._progress.experience == 75
	):
		return
	first.screen.disconnect_requested.emit()
	if not await _expect("courtyard sees the departing player", func() -> bool: return locked.players.get_child_count() == 1):
		return
	_join(first, address, port, "First")
	if not await _expect("the other contributor receives the same reward on reentry", func() -> bool:
		return _quest(first).get("quest") == 2 and first._progress.experience == 75
	):
		return
	await create_timer(second.stone_guard.respawn_delay).timeout
	second.combat.auto_requested.emit(true)
	if not await _expect("a second victory leaves experience unchanged", func() -> bool:
		return second.stone_guard.health == 0 and second._progress.experience == 75
	):
		return
	if not await _walk_to_gate(second):
		return
	second.zone_hud.travel_requested.emit()
	if await _expect("return gate reunites players in the courtyard with rewards intact", func() -> bool:
		return second.combat.zone_id == 0 and first.players.get_child_count() == 3 and second._progress.experience == 75
	):
		quit()

func _hero(client: Node) -> LunexNetworkPlayer:
	return client.players.get_node(str(client.multiplayer.get_unique_id())) as LunexNetworkPlayer

func _walk_to_gate(client: Node) -> bool:
	var hero := _hero(client)
	var gate: Marker3D = client.gates[client.combat.zone_id]
	var deadline := Time.get_ticks_msec() + 6500
	while not client.zone_hud.travel.visible and Time.get_ticks_msec() < deadline:
		var offset := gate.global_position - hero.position
		client.joystick.output = Vector2(offset.x, offset.z).normalized()
		await process_frame
	client.joystick.output = Vector2.ZERO
	return await _expect("hero approaches the gate", func() -> bool: return client.zone_hud.travel.visible)

func _quest(client: Node) -> Dictionary:
	return client._progress.get("quests", {}).get("stone_pass", {})


func _saved_chapter(client: Node) -> bool:
	var quests: Dictionary = client._progress.get("quests", {})
	return _quest(client).get("quest") == 2 and client._progress.get("experience") == 75 \
		and quests.get("training", {}).get("equipped") == "training_ring" \
		and quests.get("gate_watch", {}).get("equipped") == "watch_medallion"
