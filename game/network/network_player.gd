class_name LunexNetworkPlayer
extends LunexPlayer

var peer_id: int
var desired_direction := Vector3.ZERO
var input_time_left := 0.0
var server_position := Vector3.ZERO
var server_heading := 0.0

func prepare(id: int, spawn_position: Vector3, player_name: String) -> void:
	peer_id = id
	position = spawn_position
	server_position = spawn_position
	$PlayerName.text = player_name

func accept_input(direction: Vector3) -> void:
	desired_direction = direction.limit_length()
	input_time_left = 0.4

func _ready() -> void:
	if not multiplayer.is_server():
		collision_layer = 0
		collision_mask = 0

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		input_time_left = maxf(input_time_left - delta, 0.0)
		var direction := desired_direction if input_time_left > 0.0 else Vector3.ZERO
		simulate(direction, delta)
		server_position = position
		server_heading = $Model.rotation.y
		return

	var weight := 1.0 - exp(-22.0 * delta)
	position = position.lerp(server_position, weight)
	$Model.rotation.y = lerp_angle($Model.rotation.y, server_heading, weight)
