class_name LunexHudLayoutEditor
extends Control

signal layout_changed(action_scale: float, joystick_scale: float)

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
	reset_to_preset()

func reset_to_preset() -> void:
	action_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.action_scale))
	joystick_slider.set_value_no_signal(layout_preset.normalized_scale(layout_preset.joystick_scale))
	_apply(0.0)

func _apply(_value: float) -> void:
	action_label.text = "Кнопки: %d%%" % roundi(action_slider.value * 100.0)
	joystick_label.text = "Джойстик: %d%%" % roundi(joystick_slider.value * 100.0)
	layout_changed.emit(action_slider.value, joystick_slider.value)
