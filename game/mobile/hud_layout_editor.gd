class_name LunexHudLayoutEditor
extends Control

signal layout_changed(action_scale: float, joystick_scale: float)
signal position_changed(action_offset: Vector2, joystick_offset: Vector2)

@export var save_path: String = "user://lunex_hud_layout.cfg"

@export var layout_preset: LunexHudLayoutPreset
@onready var action_slider: HSlider = %ActionScale
@onready var joystick_slider: HSlider = %JoystickScale
@onready var action_label: Label = %ActionValue
@onready var joystick_label: Label = %JoystickValue
@onready var actions_drag: Button = %ActionsDrag
@onready var joystick_drag: Button = %JoystickDrag
var action_offset := Vector2.ZERO
var joystick_offset := Vector2.ZERO
var _drag_kind := ""
var _drag_origin := Vector2.ZERO

func _ready() -> void:
	if layout_preset == null:
		layout_preset = LunexHudLayoutPreset.new()
	action_slider.value_changed.connect(_apply)
	joystick_slider.value_changed.connect(_apply)
	%Reset.pressed.connect(reset_to_preset)
	actions_drag.gui_input.connect(func(event: InputEvent) -> void: _drag_input("actions", event))
	joystick_drag.gui_input.connect(func(event: InputEvent) -> void: _drag_input("joystick", event))
	action_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.action_scale))
	joystick_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.joystick_scale))
	load_layout()
	_apply(0.0)

func reset_to_preset() -> void:
	action_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.action_scale))
	joystick_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.joystick_scale))
	action_offset = Vector2.ZERO
	joystick_offset = Vector2.ZERO
	position_changed.emit(action_offset, joystick_offset)
	_apply(0.0)

func _apply(_value: float) -> void:
	action_label.text = "Кнопки: %d%%" % roundi(action_slider.value * 100.0)
	joystick_label.text = "Джойстик: %d%%" % roundi(joystick_slider.value * 100.0)
	layout_changed.emit(action_slider.value, joystick_slider.value)
	save_layout()

func save_layout() -> bool:
	var config := ConfigFile.new()
	config.set_value("hud", "actions", action_slider.value)
	config.set_value("hud", "joystick", joystick_slider.value)
	config.set_value("hud", "action_x", action_offset.x)
	config.set_value("hud", "action_y", action_offset.y)
	config.set_value("hud", "joystick_x", joystick_offset.x)
	config.set_value("hud", "joystick_y", joystick_offset.y)
	return config.save(save_path) == OK

func load_layout() -> bool:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return false
	var a := float(config.get_value("hud", "actions", layout_preset.action_scale))
	var j := float(config.get_value("hud", "joystick", layout_preset.joystick_scale))
	if not is_finite(a) or not is_finite(j):
		return false
	action_slider.set_value_no_signal(layout_preset.normalized_scale(a))
	joystick_slider.set_value_no_signal(layout_preset.normalized_scale(j))
	action_offset = Vector2(float(config.get_value("hud", "action_x", 0.0)), float(config.get_value("hud", "action_y", 0.0)))
	joystick_offset = Vector2(float(config.get_value("hud", "joystick_x", 0.0)), float(config.get_value("hud", "joystick_y", 0.0)))
	if not action_offset.is_finite(): action_offset = Vector2.ZERO
	if not joystick_offset.is_finite(): joystick_offset = Vector2.ZERO
	position_changed.emit(action_offset, joystick_offset)
	_apply(0.0)
	return true

static func clamp_to_safe_area(position: Vector2, element_size: Vector2, viewport_size: Vector2, margin: float) -> Vector2:
	var safe_min := Vector2.ONE * maxf(0.0, margin)
	var safe_max := (viewport_size - element_size - safe_min).max(safe_min)
	return position.clamp(safe_min, safe_max)

func _drag_input(kind: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_kind = kind
			_drag_origin = event.global_position
		else:
			_drag_kind = ""
	elif event is InputEventMouseMotion and _drag_kind == kind:
		var delta: Vector2 = event.global_position - _drag_origin
		_drag_origin = event.global_position
		if kind == "actions":
			action_offset += delta
		else:
			joystick_offset += delta
		position_changed.emit(action_offset, joystick_offset)
		save_layout()
