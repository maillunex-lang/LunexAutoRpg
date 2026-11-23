class_name LunexZoneHUD
extends Control

signal travel_requested
signal npc_requested(npc_id: String)
var selected_npc_id := ""
@onready var npc_interact: Button = %NpcInteract

@onready var location: Label = %Location
@onready var travel: Button = %Travel
@onready var notice: Label = %Notice

func _ready() -> void:
	npc_interact.pressed.connect(func() -> void: npc_requested.emit(selected_npc_id))
	travel.pressed.connect(func() -> void: travel_requested.emit())
	%NoticeTimer.timeout.connect(notice.hide)

func show_notice(message: String) -> void:
	notice.text = message
	notice.show()
	%NoticeTimer.start()
