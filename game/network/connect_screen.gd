class_name LunexConnectScreen
extends Control

signal connect_requested(address: String, port: int, player_name: String)
signal disconnect_requested

@onready var address_field: LineEdit = %Address
@onready var port_field: SpinBox = %Port
@onready var name_field: LineEdit = %PlayerName
@onready var status: Label = %Status
@onready var connect_button: Button = %Connect

func _ready() -> void:
	connect_button.pressed.connect(_request_connection)
	%Leave.pressed.connect(func() -> void: disconnect_requested.emit())
	name_field.text_submitted.connect(func(_value: String) -> void: _request_connection())

func show_connecting() -> void:
	status.text = "Подключение…"
	connect_button.disabled = true

func show_connected() -> void:
	%Form.hide()
	%Leave.show()

func show_idle(message: String) -> void:
	status.text = message
	connect_button.disabled = false
	%Leave.hide()
	%Form.show()

func _request_connection() -> void:
	if connect_button.disabled:
		return
	var address := address_field.text.strip_edges()
	var player_name := name_field.text.strip_edges()
	if address.is_empty() or player_name.is_empty():
		show_idle("Введите адрес сервера и имя.")
		return
	connect_requested.emit(address, int(port_field.value), player_name)
