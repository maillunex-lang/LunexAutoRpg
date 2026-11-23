class_name LunexStatusEffect
extends RefCounted

var effect_id: String
var expires_at_ms: int
var magnitude: int

func _init(id: String, until_ms: int, strength: int) -> void:
	effect_id = id
	expires_at_ms = until_ms
	magnitude = strength
