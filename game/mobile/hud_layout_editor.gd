class_name LunexHudLayoutEditor
extends Control

signal layout_changed(action_scale: float, joystick_scale: float)

@export var save_path: String = "user://lunex_hud_layout.cfg"

@export var layout_preset: LunexHudLayoutPreset
@onready var action_slider: HSlider = %ActionScale
@onready var joystick_slider: HSlider = %JoystickScale
@onready var action_label: Label = %ActionValue
@onready var joystick_label: Label = %JoystickValue

func _ready() -> void:
	if layout_preset == null:
		layout_preset = LunexHudLayoutPreset.new()
	action_slider.value_changed.connect(_apply)
	joystick_slider.value_changed.connect(_apply)
	%Reset.pressed.connect(reset_to_preset)
	action_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.action_scale))
	joystick_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.joystick_scale))
	load_layout()
	_apply(0.0)

func reset_to_preset() -> void:
	action_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.action_scale))
	joystick_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.joystick_scale))
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
	_apply(0.0)
	return true
