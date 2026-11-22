class_name LunexDiagnosticsHUD
extends Control

@onready var panel: PanelContainer = %Panel
@onready var values: Label = %Values

var _server: ENetPacketPeer
var _elapsed := 0.0
var _frames := 0
var _longest_frame := 0.0
var _refresh_in := 0.0

func _ready() -> void:
	%Toggle.pressed.connect(func() -> void:
		panel.visible = not panel.visible
		_refresh_in = 0.0
	)
	%Reset.pressed.connect(_reset_measurement)
	set_process(false)

func start(server: ENetPacketPeer) -> void:
	_server = server
	_reset_measurement()
	show()
	set_process(true)

func stop() -> void:
	_server = null
	set_process(false)
	panel.hide()
	hide()

func _reset_measurement() -> void:
	_elapsed = 0.0
	_frames = 0
	_longest_frame = 0.0
	_refresh_in = 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	_frames += 1
	_longest_frame = maxf(_longest_frame, delta)
	_refresh_in -= delta
	if not panel.visible or _refresh_in > 0.0:
		return
	_refresh_in = 0.5
	var rtt := "—"
	if _server != null and _server.get_state() == ENetPacketPeer.STATE_CONNECTED:
		rtt = "%d мс" % _server.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
	values.text = "Замер: %.1f с\nFPS сейчас: %.0f\nСредний FPS: %.1f\nКадр, среднее: %.1f мс\nКадр, максимум: %.1f мс\nЗадержка ENet: %s" % [
		_elapsed, Performance.get_monitor(Performance.TIME_FPS), _frames / _elapsed,
		_elapsed * 1000.0 / _frames, _longest_frame * 1000.0, rtt,
	]
