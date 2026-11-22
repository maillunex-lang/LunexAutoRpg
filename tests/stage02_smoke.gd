extends SceneTree
## Run against a clean test server using: --script tests/stage02_smoke.gd -- HOST PORT

const WORLD := preload("res://game/network/online_world.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Pass the test server host and port.")
		quit(2)
		return
	var address := args[0]
	var port := args[1].to_int()
	var first := _client("First")
	var second := _client("Second")
	_join(first, address, port, "First")
	_join(second, address, port, "Second")
	if not await _expect("both clients have two players", func() -> bool:
		return first.players.get_child_count() == 2 and second.players.get_child_count() == 2
	):
		return
	var first_id := str(first.multiplayer.get_unique_id())
	var second_id := str(second.multiplayer.get_unique_id())
	var observed_first := second.players.get_node(first_id) as LunexNetworkPlayer
	var initial_z := observed_first.position.z
	first.joystick.output = Vector2.UP
	if not await _expect("second client observes first moving", func() -> bool:
		return observed_first.position.z < initial_z - 0.6
	):
		return
	if not await _expect("server stops first at the north wall", func() -> bool:
		return observed_first.position.z < -8.9 and observed_first.position.z > -9.25
	):
		return
	await create_timer(0.25).timeout
	if observed_first.position.z < -9.25:
		push_error("FAIL: player crossed the north wall.")
		quit(1)
		return
	first.joystick.output = Vector2.ZERO
	var observed_second := first.players.get_node(second_id) as LunexNetworkPlayer
	var initial_x := observed_second.position.x
	second.joystick.output = Vector2.LEFT
	if not await _expect("first client observes second moving", func() -> bool:
		return observed_second.position.x < initial_x - 0.6
	):
		return
	second.joystick.output = Vector2.ZERO

	first.screen.disconnect_requested.emit()
	if not await _expect("departed pawn disappears for the other client", func() -> bool:
		return second.players.get_child_count() == 1 and not second.players.has_node(first_id)
	):
		return
	_join(first, address, port, "First")
	if not await _expect("reconnect restores exactly two pawns on both clients", func() -> bool:
		return first.players.get_child_count() == 2 and second.players.get_child_count() == 2
	):
		return
	first.screen.disconnect_requested.emit()
	second.screen.disconnect_requested.emit()
	second.connect_timeout.wait_time = 0.5
	var unavailable_port := 1 if port != 1 else 2
	_join(second, "127.0.0.1", unavailable_port, "Second")
	if not await _expect("failed connection re-enables the form", func() -> bool:
		return not second.screen.connect_button.disabled and second.screen.status.text == "Время подключения истекло."
	):
		return
	quit()

func _client(node_name: String) -> Node:
	var container := SubViewport.new()
	container.own_world_3d = true
	container.size = Vector2i(960, 540)
	container.name = node_name
	set_multiplayer(MultiplayerAPI.create_default_interface(), NodePath("/root/" + node_name))
	root.add_child(container)
	var client := WORLD.instantiate()
	container.add_child(client)
	client._profile_token = Crypto.new().generate_random_bytes(32).hex_encode()
	return client

func _join(client: Node, address: String, port: int, player_name: String) -> void:
	client.screen.connect_requested.emit(address, port, player_name)

func _expect(description: String, condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 6500
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			print("PASS: ", description)
			return true
		await process_frame
	push_error("FAIL: " + description)
	quit(1)
	return false


func _training(client: Node) -> Dictionary:
	var state: Dictionary = client._progress
	if state.is_empty():
		return {}
	var quests: Dictionary = state.quests
	var training: Dictionary = quests.get("training", {})
	return {
		"quest": training.get("quest", 0),
		"item": training.get("item", ""),
		"equipped": training.get("equipped", ""),
		"experience": state.experience,
	}
