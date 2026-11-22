extends "res://tests/stage05_smoke.gd"
## Run prepare and reload against separate server processes using one test database.

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
		if await _expect("both profiles retain reward and equipped ring after restart", func() -> bool:
			return _equipped(first) and _equipped(second)
		):
			quit()
		return
	if args[2] != "prepare":
		quit(2)
		return

	if not await _expect("two clients enter the same zone", func() -> bool:
		return first.players.get_child_count() == 2 and second.players.get_child_count() == 2
	):
		return
	first.diagnostics.get_node("%Toggle").pressed.emit()
	second.diagnostics.get_node("%Toggle").pressed.emit()
	if not await _expect("both diagnostics panels report frame time and connected RTT", func() -> bool:
		return _metrics_visible(first) and _metrics_visible(second)
	):
		return
	first.diagnostics.get_node("%Reset").pressed.emit()
	if not await _expect("reset starts a new diagnostics sample", func() -> bool:
		return first.diagnostics._elapsed < 0.4
	):
		return
	first.chat.message_requested.emit("Начинаем бой")
	second.chat.message_requested.emit("Готов")
	if not await _expect("both clients receive zone chat", func() -> bool:
		return first.chat.messages.has("Second: Готов") and second.chat.messages.has("First: Начинаем бой")
	):
		return

	var pawn := second.players.get_node(str(first.multiplayer.get_unique_id())) as LunexNetworkPlayer
	var initial_z := pawn.position.z
	first.joystick.output = Vector2.DOWN
	if not await _expect("the second client sees the first moving", func() -> bool:
		return pawn.position.z > initial_z + 0.8
	):
		return
	first.joystick.output = Vector2.ZERO
	for client in [first, second]:
		client.progress_hud.accept_requested.emit()
	if not await _expect("both profiles accept the quest", func() -> bool:
		return _training(first).get("quest") == 1 and _training(second).get("quest") == 1
	):
		return
	if not await _hit(first, 40):
		return
	first.screen.disconnect_requested.emit()
	if not await _expect("first fighter can leave and retain contribution", func() -> bool:
		return second.players.get_child_count() == 1
	):
		return
	if not await _hit(second, 20):
		return
	_join(first, args[0], args[1].to_int(), "First")
	if not await _expect("first fighter rejoins before victory", func() -> bool:
		return first.players.get_child_count() == 2
	):
		return
	await create_timer(0.85).timeout
	second.combat.attack_requested.emit()
	if not await _expect("manual finishing hit grants both profiles a reward", func() -> bool:
		return _awarded(first) and _awarded(second)
	):
		return
	for client in [first, second]:
		client.progress_hud.equip_requested.emit()
	if not await _expect("both profiles equip the ring", func() -> bool:
		return _equipped(first) and _equipped(second)
	):
		return
	await create_timer(14.0).timeout
	quit()

func _equipped(client: Node) -> bool:
	return _awarded(client) and _training(client).equipped == _training(client).item

func _metrics_visible(client: Node) -> bool:
	var value: String = client.diagnostics.values.text
	return client.diagnostics.panel.visible and value.contains("Кадр, среднее:") and value.contains("Задержка ENet:") and not value.ends_with("—")
