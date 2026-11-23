class_name LunexClassSelection
extends Control

signal class_requested(class_id: String)

@onready var summary: Label = $Center/Panel/Contents/Summary
@onready var confirm: Button = $Center/Panel/Contents/Confirm
@onready var choice: OptionButton = $Center/Panel/Contents/Choice
var _ids := ["warrior", "mage", "priest", "bard"]

func _ready() -> void:
	choice.clear()
	for id in _ids:
		var definition: LunexClassDefinition = load("res://game/combat/classes/" + id + ".tres")
		choice.add_item(definition.display_name)
	choice.item_selected.connect(func(_index: int) -> void: _refresh())
	confirm.pressed.connect(func() -> void:
		confirm.disabled = true
		class_requested.emit(_ids[choice.selected])
	)
	_refresh()

func show_state(state: Dictionary) -> void:
	if bool(state.get("class_selected", false)):
		hide()
		return
	var current: String = str(state.get("class_id", "warrior"))
	choice.select(maxi(0, _ids.find(current)))
	confirm.disabled = false
	_refresh()
	show()

func _refresh() -> void:
	var definition: LunexClassDefinition = load("res://game/combat/classes/" + _ids[choice.selected] + ".tres")
	summary.text = "Роль: %s\nОЗ: %d  Урон: %d\nПосле подтверждения класс изменить нельзя." % [definition.role, definition.base_health, definition.base_damage]
