@tool
class_name LunexNpcActor
extends Node3D

@export var npc_id := "mentor"
@export var display_name := "Наставник"
@export_range(0, 4) var zone_id := 0

func _ready() -> void:
    $Name.text = display_name
