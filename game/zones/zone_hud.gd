class_name LunexZoneHUD
extends Control

signal travel_requested

@onready var location: Label = %Location
@onready var travel: Button = %Travel
@onready var notice: Label = %Notice

func _ready() -> void:
	travel.pressed.connect(func() -> void: travel_requested.emit())
	%NoticeTimer.timeout.connect(notice.hide)

func show_notice(message: String) -> void:
	notice.text = message
	notice.show()
	%NoticeTimer.start()
