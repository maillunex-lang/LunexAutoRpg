class_name LunexZoneChat
extends Control

signal message_requested(message: String)

const HISTORY_LIMIT := 40
const MESSAGE_LIMIT := 200

var messages: PackedStringArray = []

@onready var panel: PanelContainer = %Panel
@onready var history: RichTextLabel = %History
@onready var input: LineEdit = %Message

func _ready() -> void:
	input.max_length = MESSAGE_LIMIT
	%Toggle.pressed.connect(func() -> void:
		panel.visible = not panel.visible
		if not panel.visible:
			input.release_focus()
	)
	%Send.pressed.connect(_submit)
	input.text_submitted.connect(func(_message: String) -> void: _submit())

func reset() -> void:
	panel.hide()
	input.clear()
	input.release_focus()
	messages.clear()
	history.clear()

func append_message(sender: String, message: String) -> void:
	if messages.size() >= HISTORY_LIMIT:
		messages.remove_at(0)
	messages.append("%s: %s" % [sender, message])
	history.text = "\n".join(messages)

func _submit() -> void:
	var message := input.text.strip_edges()
	if message.is_empty():
		return
	message_requested.emit(message)
	input.clear()
	input.release_focus()
