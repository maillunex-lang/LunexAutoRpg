extends Node3D

const PLAYER_SCENE := preload("res://game/network/network_player.tscn")
const DEFAULT_PORT := 28740
const MAX_PLAYERS := 16
const INPUT_INTERVAL := 0.05

@onready var players: Node3D = $Players
@onready var spawner: MultiplayerSpawner = $PlayerSpawner
@onready var camera: LunexFollowCamera = $FollowCamera
@onready var joystick: LunexVirtualJoystick = $HUD/VirtualJoystick
@onready var screen: LunexConnectScreen = $HUD/ConnectScreen
@onready var connect_timeout: Timer = $ConnectTimeout

@onready var enemy: LunexTrainingEnemy = $TrainingEnemy
@onready var combat: LunexCombatHUD = $HUD/CombatHUD

var _peer: ENetMultiplayerPeer
var _player_name := ""
var _local_player: LunexNetworkPlayer
var _input_elapsed := 0.0
var _spawn_slots: Dictionary[int, int] = {}

func _ready() -> void:
	spawner.spawn_function = _spawn_player
	spawner.spawned.connect(_player_spawned)
	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		_start_server(args)
		return

	combat.attack_requested.connect(func() -> void: _request_attack.rpc_id(1))
	combat.auto_requested.connect(func(enabled: bool) -> void: _request_auto.rpc_id(1, enabled))
	screen.connect_requested.connect(_connect_client)
	screen.disconnect_requested.connect(func() -> void: _close_client("Вы вышли из мира."))
	multiplayer.connected_to_server.connect(func() -> void: _join.rpc_id(1, _player_name))
	multiplayer.connection_failed.connect(func() -> void: _close_client("Сервер недоступен. Попробуйте снова."))
	multiplayer.server_disconnected.connect(func() -> void: _close_client("Связь с сервером потеряна."))
	connect_timeout.timeout.connect(func() -> void: _close_client("Время подключения истекло."))

func _start_server(args: PackedStringArray) -> void:
	var port := DEFAULT_PORT
	for arg in args:
		if arg.begins_with("--port="):
			port = arg.trim_prefix("--port=").to_int()
	if port < 1 or port > 65535:
		push_error("Invalid server UDP port.")
		get_tree().quit(1)
		return
	_peer = ENetMultiplayerPeer.new()
	var result := _peer.create_server(port, MAX_PLAYERS)
	if result != OK:
		push_error("Could not start ENet server: " + error_string(result))
		get_tree().quit(1)
		return
	(multiplayer as SceneMultiplayer).server_relay = false
	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_disconnected.connect(_remove_player)
	$HUD.hide()
	print("Lunex server listening on UDP ", port)

func _connect_client(address: String, port: int, player_name: String) -> void:
	if _peer != null:
		return
	_player_name = player_name
	var client := ENetMultiplayerPeer.new()
	var result := client.create_client(address, port)
	if result != OK:
		screen.show_idle("Не удалось открыть соединение.")
		return

	_peer = client
	multiplayer.multiplayer_peer = _peer
	screen.show_connecting()
	connect_timeout.start()

func _close_client(message: String) -> void:
	connect_timeout.stop()
	_local_player = null
	camera.follow(null)
	joystick.hide()
	combat.hide()
	combat.selected = false
	screen.show_idle(message)
	if _peer != null:
		var closing := _peer
		_peer = null
		multiplayer.multiplayer_peer = null
		closing.close()
	for player in players.get_children():
		players.remove_child(player)
		player.queue_free()

@rpc("any_peer", "call_remote", "reliable")
func _join(value: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id <= 1 or _spawn_slots.has(id):
		return
	var player_name := value.strip_edges().left(20)
	if player_name.is_empty() or player_name.contains("\n") or player_name.contains("\r"):
		_peer.disconnect_peer(id)
		return

	for slot in range(MAX_PLAYERS):
		if _spawn_slots.values().has(slot):
			continue
		_spawn_slots[id] = slot
		var spawn := Vector3((slot % 4) * 2.0 - 3.0, 0.1, floori(slot / 4.0) * 2.0)
		spawner.spawn([id, spawn, player_name])
		break

func _spawn_player(data: Variant) -> Node:
	var player := PLAYER_SCENE.instantiate() as LunexNetworkPlayer
	player.name = str(data[0])
	player.prepare(data[0], data[1], data[2])
	player.enemy = enemy
	return player

func _player_spawned(node: Node) -> void:
	var player := node as LunexNetworkPlayer
	if player.peer_id != multiplayer.get_unique_id():
		return
	_local_player = player
	_input_elapsed = INPUT_INTERVAL
	camera.follow(player)
	joystick.show()
	combat.show()
	connect_timeout.stop()
	screen.show_connected()

func _remove_player(id: int) -> void:
	_spawn_slots.erase(id)
	var player := players.get_node_or_null(str(id))
	if player != null:
		player.queue_free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_local_player):
		return
	combat.refresh(enemy, _local_player.auto_enabled)
	_input_elapsed += delta
	if _input_elapsed < INPUT_INTERVAL:
		return
	_input_elapsed = fmod(_input_elapsed, INPUT_INTERVAL)
	var direction := LunexPlayer.camera_relative_direction(joystick.output, camera)
	_move.rpc_id(1, Vector2(direction.x, direction.z))

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _move(direction: Vector2) -> void:
	if not multiplayer.is_server() or not direction.is_finite():
		return
	var player := _sender_player()
	if player != null:
		player.accept_input(Vector3(direction.x, 0.0, direction.y))


func _sender_player() -> LunexNetworkPlayer:
	if not multiplayer.is_server():
		return null
	return players.get_node_or_null(str(multiplayer.get_remote_sender_id())) as LunexNetworkPlayer

@rpc("any_peer", "call_remote", "reliable")
func _request_attack() -> void:
	var player := _sender_player()
	if player != null:
		player.attack_requested = true

@rpc("any_peer", "call_remote", "reliable")
func _request_auto(enabled: bool) -> void:
	var player := _sender_player()
	if player != null:
		player.set_auto(enabled)
