class_name LunexStoryCinematic
extends Control

signal finished

@export_multiline var text_lines: PackedStringArray = PackedStringArray(["Колокол стихает.", "Но в тумане всё ещё слышен чужой шёпот."])
@export_range(0.5, 12.0, 0.5) var seconds_per_line := 3.5

@onready var story_text: Label = %StoryText
@onready var skip_button: Button = %Skip
var _index := 0
var _time_left := 0.0

func _ready() -> void:
    hide()
    skip_button.pressed.connect(close_cinematic)

func begin() -> void:
    _index = 0
    _time_left = seconds_per_line
    show()
    _display_line()

func _display_line() -> void:
    if _index >= text_lines.size():
        close_cinematic()
        return
    story_text.text = text_lines[_index]

func _process(delta: float) -> void:
    if not visible:
        return
    _time_left -= delta
    if _time_left <= 0.0:
        _index += 1
        _time_left = seconds_per_line
        _display_line()

func close_cinematic() -> void:
    if not visible:
        return
    hide()
    finished.emit()
