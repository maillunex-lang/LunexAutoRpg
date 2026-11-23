extends Node3D

const PLAYER_SCENE := preload("res://game/network/network_player.tscn")
const DEFAULT_PORT := 28740
const MAX_PLAYERS := 16
const NPC_DISTANCE := 2.5
const INPUT_INTERVAL := 0.05
const PROFILE_PATH := "user://test_profile.cfg"
const DEFAULT_DATABASE := "user://progress.sqlite"

@export_range(0.5, 8.0, 0.1) var gate_distance := 2.4
@export var courtyard_name := "Тренировочный двор"
@export var passage_name := "Каменный проход"
@export var quest_rewards: Array[LunexQuestReward]
@export var chapter_quest_definitions: Array[LunexChapterQuestDefinition] = []
@export_range(1, 100000) var level_two_experience := 50

@onready var players: Node3D = $Players
@onready var npcs: Node3D = $NPCs
@onready var dialogue_window: LunexDialogueWindow = $HUD/DialogueWindow
@onready var spawner: MultiplayerSpawner = $PlayerSpawner
@onready var camera: LunexFollowCamera = $FollowCamera
@onready var joystick: LunexVirtualJoystick = $HUD/VirtualJoystick
@onready var screen: LunexConnectScreen = $HUD/ConnectScreen
@onready var connect_timeout: Timer = $ConnectTimeout

@onready var enemy: LunexTrainingEnemy = $TrainingEnemy
@onready var watch: LunexGateWatch = $GateWatch
@onready var stone_guard: LunexTrainingEnemy = $StoneGuard
@onready var targets: Array[LunexTrainingEnemy] = [enemy, watch, stone_guard]
@onready var gates: Array[Marker3D] = [$CourtyardGate, $Passage/ReturnGate]
@onready var arrivals: Array[Marker3D] = [$CourtyardArrival, $Passage/Arrival]
@onready var zone_hud: LunexZoneHUD = $HUD/ZoneHUD
@onready var passage: NavigationRegion3D = $Passage
@onready var combat: LunexCombatHUD = $HUD/CombatHUD

@onready var diagnostics: LunexDiagnosticsHUD = $HUD/DiagnosticsHUD
@onready var chat: LunexZoneChat = $HUD/ZoneChat
@onready var progress_hud: LunexProgressHUD = $HUD/ProgressHUD
@onready var class_selection: LunexClassSelection = $HUD/ClassSelection

var _metrics_enabled := false
var _metrics_elapsed := 0.0
var _physics_sample_count := 0
var _physics_total_ms := 0.0
var _physics_max_ms := 0.0

var _store := LunexProgressStore.new()
var _ability_engine := LunexAbilityExecutor.new()
const WARRIOR_SKILLS := ["warrior_strike", "warrior_shield"]
const MAGE_SKILLS := ["mage_bolt", "mage_fireball"]
const PRIEST_SKILLS := ["priest_heal", "priest_blessing"]
const BARD_SKILLS := ["bard_song", "bard_restore"]
const CLASS_SKILLS := {
	"warrior": WARRIOR_SKILLS,
	"mage": MAGE_SKILLS,
	"priest": PRIEST_SKILLS,
	"bard": BARD_SKILLS
}
const ABILITY_CATALOG := {
	"warrior_strike": "res://game/combat/abilities/warrior_strike.tres",
	"warrior_shield": "res://game/combat/abilities/warrior_shield.tres",
	"mage_bolt": "res://game/combat/abilities/mage_bolt.tres",
	"mage_fireball": "res://game/combat/abilities/mage_fireball.tres",
	"priest_heal": "res://game/combat/abilities/priest_heal.tres",
	"priest_blessing": "res://game/combat/abilities/priest_blessing.tres",
	"bard_song": "res://game/combat/abilities/bard_song.tres",
	"bard_restore": "res://game/combat/abilities/bard_restore.tres"
}
var _profiles: Dictionary[int, String] = {}
var _contributors: Dictionary[String, Dictionary] = {}
var _chat_next_ms: Dictionary[int, int] = {}
var _profile_token := ""
var _progress: Dictionary = {}
var _peer: ENetMultiplayerPeer
var _player_name := ""
var _local_player: LunexNetworkPlayer
var _input_elapsed := 0.0
var _spawn_slots: Dictionary[int, int] = {}

func _ready() -> void:
	combat.targets = targets
	_show_zone(0)
	spawner.spawn_function = _spawn_player
	for path: String in ABILITY_CATALOG.values():
		if not _ability_engine.register(load(path) as LunexAbilityDefinition):
			push_error("Invalid combat ability resource: " + path)
	spawner.spawned.connect(_player_spawned)
	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		_start_server(args)
		return

	class_selection.class_requested.connect(func(class_id: String) -> void: _choose_class.rpc_id(1, class_id))
	combat.skill_requested.connect(func(ability_id: String) -> void: _request_skill.rpc_id(1, ability_id, combat.target_index))
	combat.attack_requested.connect(func() -> void: _request_attack.rpc_id(1, combat.target_index))
	combat.auto_requested.connect(func(enabled: bool) -> void: _request_auto.rpc_id(1, enabled, combat.target_index))
	progress_hud.accept_requested.connect(func() -> void: _accept_quest.rpc_id(1, progress_hud.selected_quest))
	progress_hud.equip_requested.connect(func() -> void: _equip_reward.rpc_id(1, progress_hud.selected_quest))
	progress_hud.quest_route_requested.connect(func(quest_id: String) -> void: _request_quest_route.rpc_id(1, quest_id))
	chat.message_requested.connect(func(message: String) -> void: _send_chat.rpc_id(1, message))
	zone_hud.npc_requested.connect(func(npc_id: String) -> void: _request_npc.rpc_id(1, npc_id))
	dialogue_window.quest_accept_requested.connect(func(quest_id: String) -> void: _chapter_accept.rpc_id(1, quest_id))
	zone_hud.travel_requested.connect(func() -> void: _request_travel.rpc_id(1, combat.zone_id))
	screen.connect_requested.connect(_connect_client)
	screen.disconnect_requested.connect(func() -> void: _close_client("Вы вышли из мира."))
	multiplayer.connected_to_server.connect(func() -> void: _join.rpc_id(1, _player_name, _profile_token))
	multiplayer.connection_failed.connect(func() -> void: _close_client("Сервер недоступен. Попробуйте снова."))
	multiplayer.server_disconnected.connect(func() -> void: _close_client("Связь с сервером потеряна."))
	connect_timeout.timeout.connect(func() -> void: _close_client("Время подключения истекло."))

func _start_server(args: PackedStringArray) -> void:
	_metrics_enabled = "--metrics" in args
	var port := DEFAULT_PORT
	var database := DEFAULT_DATABASE
	for arg in args:
		if arg.begins_with("--port="):
			port = arg.trim_prefix("--port=").to_int()
		elif arg.begins_with("--database="):
			database = arg.trim_prefix("--database=")
	if port < 1 or port > 65535:
		push_error("Invalid server UDP port.")
		get_tree().quit(1)
		return
	if not _store.open(database):
		push_error("Could not open progression database.")
		get_tree().quit(1)
		return
	watch.players = players
	for target in targets:
		(target.get_node("State") as MultiplayerSynchronizer).public_visibility = false
		target.hit_landed.connect(_record_hit.bind(target.target_id))
		target.defeated.connect(_reward_contributors.bind(target.target_id))
	_peer = ENetMultiplayerPeer.new()
	var result := _peer.create_server(port, MAX_PLAYERS, 2)
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
	if not _open_local_profile():
		screen.show_idle("Не удалось открыть локальный тестовый профиль.")
		return
	_player_name = player_name
	var client := ENetMultiplayerPeer.new()
	var result := client.create_client(address, port, 2)
	if result != OK:
		screen.show_idle("Не удалось открыть соединение.")
		return

	_peer = client
	multiplayer.multiplayer_peer = _peer
	screen.show_connecting()
	connect_timeout.start()

func _close_client(message: String) -> void:
	connect_timeout.stop()
	diagnostics.stop()
	_local_player = null
	camera.follow(null)
	joystick.hide()
	combat.hide()
	combat.reset_skill_ui()
	combat.selected = false
	combat.target_index = 0
	zone_hud.hide()
	zone_hud.npc_interact.hide()
	dialogue_window.close_dialogue()
	_show_zone(0)
	chat.hide()
	chat.reset()
	progress_hud.hide()
	progress_hud.reset()
	class_selection.hide()
	_progress.clear()
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
func _join(value: String, token: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id <= 1 or _spawn_slots.has(id):
		return
	var player_name := value.strip_edges().left(20)
	if player_name.is_empty() or player_name.contains("\n") or player_name.contains("\r"):
		_peer.disconnect_peer(id)
		return

	if token.length() != 64 or not token.is_valid_hex_number():
		_reject_login.rpc_id(id, "Некорректный тестовый профиль.")
		return
	var profile := token.to_lower().sha256_text()
	if _profiles.values().has(profile):
		_reject_login.rpc_id(id, "Этот профиль уже в игре.")
		return
	var state := _store.load_profile(profile)
	if state.is_empty():
		_reject_login.rpc_id(id, "Сохранение временно недоступно.")
		return

	for slot in range(MAX_PLAYERS):
		if _spawn_slots.values().has(slot):
			continue
		_spawn_slots[id] = slot
		_profiles[id] = profile
		var spawn := Vector3((slot % 4) * 2.0 - 3.0, 0.1, floori(slot / 4.0) * 2.0)
		var player := spawner.spawn([id, spawn, player_name, state.class_id]) as LunexNetworkPlayer
		if player == null:
			_spawn_slots.erase(id)
			_profiles.erase(id)
			_reject_login.rpc_id(id, "Не удалось создать персонажа.")
			return
		_update_zone_visibility(player)
		_receive_progress.rpc_id(id, state)
		break

func _spawn_player(data: Variant) -> Node:
	var player := PLAYER_SCENE.instantiate() as LunexNetworkPlayer
	player.name = str(data[0])
	player.prepare(data[0], data[1], data[2], data[3] if data.size() > 3 else "warrior")
	player.enemy = enemy
	if multiplayer.is_server():
		(player.get_node("State") as MultiplayerSynchronizer).public_visibility = false
	return player

func _player_spawned(node: Node) -> void:
	var player := node as LunexNetworkPlayer
	if player.peer_id != multiplayer.get_unique_id():
		return
	_local_player = player
	_input_elapsed = INPUT_INTERVAL
	camera.follow(player)
	diagnostics.start(_peer.get_peer(1))
	joystick.show()
	chat.show()
	progress_hud.show()
	combat.show()
	zone_hud.show()
	connect_timeout.stop()
	screen.show_connected()

func _remove_player(id: int) -> void:
	_spawn_slots.erase(id)
	_profiles.erase(id)
	_chat_next_ms.erase(id)
	_ability_engine.clear_actor(id)
	var player := players.get_node_or_null(str(id))
	if player != null:
		player.queue_free()

func _physics_process(delta: float) -> void:
	if _metrics_enabled:
		_sample_server(delta)
	if not is_instance_valid(_local_player):
		return
	combat.refresh(_local_player)
	combat.refresh_skills(_local_player.class_id, int(_progress.get("experience", 0)), _local_player.ability_energy)
	zone_hud.travel.visible = _local_player.health > 0 and _local_player.global_position.distance_to(gates[_local_player.zone_id].global_position) <= gate_distance
	var nearest: LunexNpcActor = null
	for candidate in npcs.get_children():
		var npc := candidate as LunexNpcActor
		if npc.zone_id != _local_player.zone_id:
			continue
		if _local_player.global_position.distance_to(npc.global_position) <= NPC_DISTANCE:
			nearest = npc
			break
	zone_hud.npc_interact.visible = nearest != null and _local_player.health > 0
	if nearest != null:
		zone_hud.selected_npc_id = nearest.npc_id
		zone_hud.npc_interact.text = "Поговорить: " + nearest.display_name
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
func _request_attack(index: int) -> void:
	var player := _sender_player()
	if player != null and player.health > 0 and index >= 0 and index < targets.size() and targets[index].zone_id == player.zone_id:
		player.set_target(targets[index])
		player.attack_requested = true

@rpc("any_peer", "call_remote", "reliable")
func _request_skill(ability_id: String, target_index: int) -> void:
	var player := _sender_player()
	if player == null or player.health <= 0 or ability_id.is_empty() or ability_id.length() > 40:
		return
	var profile: String = _profiles.get(player.peer_id, "")
	if profile.is_empty():
		return
	var state := _store.read_profile(profile)
	if state.is_empty() or not bool(state.get("class_selected", false)):
		return
	var class_id: String = str(state.get("class_id", "warrior"))
	if class_id != player.class_id or not ABILITY_CATALOG.has(ability_id):
		return
	var skill: LunexAbilityDefinition = load(ABILITY_CATALOG[ability_id])
	if skill == null or not skill.is_valid() or skill.class_id != class_id:
		return
	var level := 2 if int(state.get("experience", 0)) >= level_two_experience else 1
	var learned := PackedStringArray()
	for id: String in CLASS_SKILLS.get(class_id, []):
		var candidate: LunexAbilityDefinition = load(ABILITY_CATALOG[id])
		if candidate != null and candidate.unlock_level <= level:
			learned.append(id)
	var target: LunexTrainingEnemy = null
	var ally: LunexNetworkPlayer = player
	if skill.target_kind == "enemy":
		if target_index < 0 or target_index >= targets.size():
			return
		target = targets[target_index]
	elif skill.target_kind == "ally":
		ally = _nearest_ally(player, skill.max_range, skill.effect_kind == "heal")
		if ally == null:
			_skill_feedback.rpc_id(player.peer_id, "no_ally", player.ability_energy)
			return
	var target_position := target.global_position if target != null else ally.global_position
	var same_zone := player.zone_id == target.zone_id if target != null else player.zone_id == ally.zone_id
	var visible := player.has_line_of_sight(target_position) if target != null else (player.has_line_of_sight(target_position) if ally != player else true)
	if target != null:
		visible = visible and target.health > 0
	var result := _ability_engine.try_cast(player.peer_id, class_id, level, learned, int(player.ability_energy), ability_id, player.global_position, target_position, skill.target_kind, same_zone, visible, Time.get_ticks_msec())
	if not result.get("ok", false):
		_skill_feedback.rpc_id(player.peer_id, str(result.get("reason", "unavailable")), player.ability_energy)
		return
	player.ability_energy = float(result.resource_left)
	player.manual_skill_priority_left = 0.45
	if result.effect_kind == "damage" and target != null:
		target.take_hit(int(result.magnitude), player.peer_id)
		player.attack_sequence += 1
	elif result.effect_kind == "heal":
		ally.heal(int(result.magnitude))
	elif result.effect_kind == "status":
		if skill.status_id == "shield":
			ally.apply_shield(int(result.magnitude), float(skill.status_duration))
		elif skill.status_id == "blessing":
			ally.apply_blessing(int(result.magnitude), float(skill.status_duration))
		elif skill.status_id == "song":
			for candidate in players.get_children():
				var member := candidate as LunexNetworkPlayer
				if member != null and member.health > 0 and member.zone_id == player.zone_id and member.global_position.distance_to(player.global_position) <= skill.max_range:
					member.apply_blessing(int(result.magnitude), float(skill.status_duration))
	_skill_feedback.rpc_id(player.peer_id, "ok:" + ability_id, player.ability_energy, int(result.cooldown_until_ms) - Time.get_ticks_msec())

# Server chooses an eligible ally, not a client-supplied peer ID.
func _nearest_ally(caster: LunexNetworkPlayer, radius: float, injured_only: bool) -> LunexNetworkPlayer:
	var best: LunexNetworkPlayer = null
	var distance := INF
	for candidate in players.get_children():
		var ally := candidate as LunexNetworkPlayer
		if ally == null or ally.health <= 0 or ally.zone_id != caster.zone_id:
			continue
		if injured_only and ally.health >= ally.max_health:
			continue
		var d := caster.global_position.distance_to(ally.global_position)
		if d <= radius and d < distance:
			best = ally
			distance = d
	return best

@rpc("authority", "call_remote", "reliable")
func _skill_feedback(message: String, energy: float, cooldown_ms: int = 0) -> void:
	if is_instance_valid(_local_player):
		_local_player.ability_energy = energy
	combat.show_skill_feedback(message, cooldown_ms)

@rpc("any_peer", "call_remote", "reliable")
func _request_auto(enabled: bool, index: int) -> void:
	var player := _sender_player()
	if player != null and index >= 0 and index < targets.size() and targets[index].zone_id == player.zone_id:
		player.set_target(targets[index])
		player.set_auto(enabled)


func _open_local_profile() -> bool:
	if not _profile_token.is_empty():
		return true
	var config := ConfigFile.new()
	if FileAccess.file_exists(PROFILE_PATH):
		if config.load(PROFILE_PATH) != OK:
			return false
		var saved: String = config.get_value("profile", "token", "")
		if saved.length() != 64 or not saved.is_valid_hex_number():
			return false
		_profile_token = saved
		return true
	var generated := Crypto.new().generate_random_bytes(32).hex_encode()
	if generated.length() != 64:
		return false
	config.set_value("profile", "token", generated)
	if config.save(PROFILE_PATH) != OK:
		return false
	_profile_token = generated
	return true

@rpc("authority", "call_remote", "reliable")
func _reject_login(message: String) -> void:
	_close_client.call_deferred(message)

@rpc("authority", "call_remote", "reliable")
func _receive_progress(state: Dictionary) -> void:
	_progress = state
	progress_hud.show_state(state, quest_rewards, level_two_experience, chapter_quest_definitions)
	dialogue_window.set_quest_state(state.get("chapter_quests", {}), chapter_quest_definitions)
	class_selection.show_state(state)

@rpc("any_peer", "call_remote", "reliable")
func _choose_class(class_id: String) -> void:
	var player := _sender_player()
	if player == null:
		return
	var profile: String = _profiles.get(player.peer_id, "")
	if profile.is_empty() or not _store.assign_class(profile, class_id):
		_publish_progress(player.peer_id, profile) if not profile.is_empty() else _reject_login.rpc_id(player.peer_id, "Профиль недоступен.")
		return
	player.update_class(class_id)
	_class_changed.rpc(class_id, player.peer_id)
	_publish_progress(player.peer_id, profile)

@rpc("authority", "call_remote", "reliable")
func _class_changed(class_id: String, player_id: int) -> void:
	var player := players.get_node_or_null(str(player_id)) as LunexNetworkPlayer
	if player != null:
		player.update_class(class_id)

@rpc("any_peer", "call_remote", "reliable")
func _request_quest_route(quest_id: String) -> void:
	var player := _sender_player()
	if player == null or player.health <= 0 or quest_id.length() > 64:
		return
	var definition := _chapter_definition(quest_id)
	if definition == null:
		return
	var profile: String = _profiles.get(player.peer_id, "")
	if profile.is_empty() or not _store.is_chapter_active(profile, quest_id):
		return
	for candidate in npcs.get_children():
		var npc := candidate as LunexNpcActor
		if npc.npc_id != definition.objective_npc_id:
			continue
		if npc.zone_id == player.zone_id:
			player.set_quest_destination(npc.global_position)
			_quest_route_notice.rpc_id(player.peer_id, "Автопуть: " + npc.display_name)
		else:
			player.set_quest_destination(gates[player.zone_id].global_position)
			_quest_route_notice.rpc_id(player.peer_id, "Автопуть до ворот. Переход в другую локацию вручную.")
		return

@rpc("authority", "call_remote", "reliable")
func _quest_route_notice(message: String) -> void:
	zone_hud.show_notice(message)

func _chapter_definition(quest_id: String) -> LunexChapterQuestDefinition:
	for definition in chapter_quest_definitions:
		if definition != null and definition.quest_id == quest_id:
			return definition
	return null

@rpc("any_peer", "call_remote", "reliable")
func _chapter_accept(quest_id: String) -> void:
	var player := _sender_player()
	if player == null or player.health <= 0 or quest_id.length() > 64:
		return
	var definition := _chapter_definition(quest_id)
	if definition == null or definition.npc_id.is_empty():
		return
	if not _npc_near_player(player, definition.npc_id):
		return
	var profile: String = _profiles.get(player.peer_id, "")
	if not profile.is_empty() and _store.chapter_accept(profile, definition.quest_id, definition.prerequisite_id):
		_publish_progress(player.peer_id, profile)

# Objective events originate exclusively from validated NPC interactions.
func _chapter_npc_objective(peer_id: int, npc_id: String) -> void:
	if not multiplayer.is_server():
		return
	var profile: String = _profiles.get(peer_id, "")
	if profile.is_empty():
		return
	for definition in chapter_quest_definitions:
		if definition.objective_npc_id != npc_id:
			continue
		if not _store.is_chapter_active(profile, definition.quest_id):
			continue
		if _chapter_record_verified_objective(peer_id, definition.quest_id):
			_chapter_complete_verified(peer_id, definition.quest_id)

func _npc_near_player(player: LunexNetworkPlayer, npc_id: String) -> bool:
	if player == null or player.health <= 0:
		return false
	for candidate in npcs.get_children():
		var npc := candidate as LunexNpcActor
		if npc.npc_id == npc_id and npc.zone_id == player.zone_id and player.global_position.distance_to(npc.global_position) <= NPC_DISTANCE:
			return true
	return false

# Server-side only. Future NPC/objective events must call this after validation.
func _chapter_record_verified_objective(peer_id: int, quest_id: String) -> bool:
	if not multiplayer.is_server():
		return false
	var player := players.get_node_or_null(str(peer_id)) as LunexNetworkPlayer
	var definition := _chapter_definition(quest_id)
	if player == null or definition == null or player.health <= 0:
		return false
	var profile: String = _profiles.get(peer_id, "")
	if profile.is_empty():
		return false
	if not _store.chapter_advance(profile, quest_id, 1, definition.objective_goal):
		return false
	_publish_progress(peer_id, profile)
	return true

func _chapter_complete_verified(peer_id: int, quest_id: String) -> bool:
	if not multiplayer.is_server():
		return false
	var definition := _chapter_definition(quest_id)
	var profile: String = _profiles.get(peer_id, "")
	if definition == null or profile.is_empty():
		return false
	if not _store.chapter_complete(profile, quest_id, definition.objective_goal):
		return false
	_publish_progress(peer_id, profile)
	return true

func _publish_progress(peer_id: int, profile: String) -> void:
	var state := _store.read_profile(profile)
	if not state.is_empty():
		_receive_progress.rpc_id(peer_id, state)

@rpc("any_peer", "call_remote", "reliable")
func _accept_quest(index: int) -> void:
	var player := _sender_player()
	if player != null and index >= 0 and index < quest_rewards.size():
		var profile: String = _profiles[player.peer_id]
		if _store.accept(profile, quest_rewards[index]):
			_publish_progress(player.peer_id, profile)

@rpc("any_peer", "call_remote", "reliable")
func _equip_reward(index: int) -> void:
	var player := _sender_player()
	if player != null and index >= 0 and index < quest_rewards.size():
		var profile: String = _profiles[player.peer_id]
		if _store.equip(profile, quest_rewards[index].quest_id):
			_publish_progress(player.peer_id, profile)

func _record_hit(peer_id: int, target_id: String) -> void:
	var profile: String = _profiles.get(peer_id, "")
	if profile.is_empty():
		return
	for reward in quest_rewards:
		if reward.target_id != target_id:
			continue
		var earned: Dictionary = _contributors.get_or_add(reward.quest_id, {})
		if not earned.has(profile) and _store.is_active(profile, reward.quest_id):
			earned[profile] = true

func _reward_contributors(target_id: String) -> void:
	for reward in quest_rewards:
		if reward.target_id != target_id:
			continue
		var earned: Dictionary = _contributors.get(reward.quest_id, {})
		_contributors.erase(reward.quest_id)
		for profile: String in earned:
			if _store.complete(profile, reward):
				var online_peer: Variant = _profiles.find_key(profile)
				if online_peer != null:
					_publish_progress(online_peer, profile)

@rpc("any_peer", "call_remote", "reliable", 1)
func _send_chat(value: String) -> void:
	var sender := _sender_player()
	if sender == null:
		return
	var now := Time.get_ticks_msec()
	if now < _chat_next_ms.get(sender.peer_id, 0):
		return
	var message := value.left(LunexZoneChat.MESSAGE_LIMIT).strip_edges()
	if message.is_empty() or message.contains("\n") or message.contains("\r"):
		return
	_chat_next_ms[sender.peer_id] = now + 1000
	for child in players.get_children():
		var recipient := child as LunexNetworkPlayer
		if _profiles.has(recipient.peer_id) and recipient.zone_id == sender.zone_id:
			_receive_chat.rpc_id(recipient.peer_id, sender.display_name, message, sender.zone_id)

@rpc("authority", "call_remote", "reliable", 1)
func _receive_chat(sender: String, message: String, zone_id: int) -> void:
	if combat.zone_id == zone_id:
		chat.append_message(sender, message)


func _sample_server(delta: float) -> void:
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_metrics_elapsed += delta
	_physics_sample_count += 1
	_physics_total_ms += physics_ms
	_physics_max_ms = maxf(_physics_max_ms, physics_ms)
	if _metrics_elapsed < 5.0:
		return
	if not _profiles.is_empty():
		print("LUNEX_METRICS players=%d physics_mean_ms=%.3f physics_max_ms=%.3f ticks=%d" % [
			_profiles.size(), _physics_total_ms / _physics_sample_count, _physics_max_ms, _physics_sample_count,
		])
	_metrics_elapsed = 0.0
	_physics_sample_count = 0
	_physics_total_ms = 0.0
	_physics_max_ms = 0.0


func _update_zone_visibility(player: LunexNetworkPlayer) -> void:
	var state := player.get_node("State") as MultiplayerSynchronizer
	for child in players.get_children():
		var other := child as LunexNetworkPlayer
		if not _profiles.has(other.peer_id):
			continue
		var same_zone := other.zone_id == player.zone_id
		state.set_visibility_for(other.peer_id, same_zone)
		if other != player:
			(other.get_node("State") as MultiplayerSynchronizer).set_visibility_for(player.peer_id, same_zone)
	for target in targets:
		(target.get_node("State") as MultiplayerSynchronizer).set_visibility_for(player.peer_id, target.zone_id == player.zone_id)

@rpc("any_peer", "call_remote", "reliable")
func _request_travel(previous_zone: int) -> void:
	var player := _sender_player()
	if player == null or player.health <= 0:
		return
	var current := player.zone_id
	if previous_zone != current:
		return
	if player.global_position.distance_to(gates[current].global_position) > gate_distance:
		_travel_notice.rpc_id(player.peer_id, "Подойдите ближе к воротам.")
		return
	if current == 0:
		var state := _store.read_profile(_profiles[player.peer_id])
		var watch_quest: Dictionary = state.get("quests", {}).get("gate_watch", {})
		if watch_quest.get("quest") != LunexProgressStore.Quest.COMPLETE:
			_travel_notice.rpc_id(player.peer_id, "Сначала завершите «Дозор у ворот».")
			return
	var next := 1 - current
	var arrival := arrivals[next].global_position
	arrival.x += float(_spawn_slots[player.peer_id] % 4) * 0.65 - 0.975
	player.enter_zone(next, arrival)
	player.set_target(stone_guard if next == 1 else enemy)
	_arrive.rpc_id(player.peer_id, next, arrival)
	_update_zone_visibility(player)

@rpc("authority", "call_remote", "reliable")
func _travel_notice(message: String) -> void:
	zone_hud.show_notice(message)

@rpc("authority", "call_remote", "reliable")
func _arrive(next: int, arrival: Vector3) -> void:
	if not is_instance_valid(_local_player):
		return
	_local_player.enter_zone(next, arrival)
	camera.follow(_local_player)
	chat.reset()
	_show_zone(next)

@rpc("any_peer", "call_remote", "reliable")
func _request_npc(npc_id: String) -> void:
	var player := _sender_player()
	if player == null or player.health <= 0 or npc_id.length() > 32:
		return
	for candidate in npcs.get_children():
		var npc := candidate as LunexNpcActor
		if npc.npc_id != npc_id:
			continue
		if npc.zone_id != player.zone_id or player.global_position.distance_to(npc.global_position) > NPC_DISTANCE:
			_npc_notice.rpc_id(player.peer_id, "Подойдите к персонажу.")
			return
		_chapter_npc_objective(player.peer_id, npc.npc_id)
		_npc_open.rpc_id(player.peer_id, npc.npc_id)
		return

@rpc("authority", "call_remote", "reliable")
func _npc_open(npc_id: String) -> void:
	dialogue_window.open_dialogue(npc_id)

@rpc("authority", "call_remote", "reliable")
func _npc_notice(message: String) -> void:
	zone_hud.show_notice(message)

func _show_zone(zone_id: int) -> void:
	combat.enter_zone(zone_id, 0 if zone_id == 0 else 2)
	for target in targets:
		target.visible = target.zone_id == zone_id
	for npc in npcs.get_children():
		npc.visible = npc.zone_id == zone_id
	zone_hud.location.text = courtyard_name if zone_id == 0 else passage_name
	zone_hud.travel.text = "Войти в проход" if zone_id == 0 else "Вернуться во двор"
	zone_hud.notice.hide()
