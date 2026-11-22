class_name LunexProgressHUD
extends Control

signal accept_requested
signal equip_requested

var selected_quest := 0
var _state: Dictionary = {}
var _rewards: Array[LunexQuestReward] = []
var _level_two_experience := 50

func _ready() -> void:
	%Progress.pressed.connect(func() -> void: %Panel.visible = not %Panel.visible)
	%Close.pressed.connect(func() -> void: %Panel.hide())
	%Accept.pressed.connect(func() -> void: accept_requested.emit())
	%Equip.pressed.connect(func() -> void: equip_requested.emit())
	%Chapters.item_selected.connect(func(index: int) -> void:
		selected_quest = index
		_refresh()
	)
	reset()

func reset() -> void:
	%Panel.hide()
	%Progress.disabled = true
	selected_quest = 0
	_state.clear()

func show_state(state: Dictionary, rewards: Array[LunexQuestReward], level_two_experience: int) -> void:
	_state = state
	_rewards = rewards
	_level_two_experience = level_two_experience
	%Progress.disabled = false
	%Chapters.clear()
	for reward in rewards:
		%Chapters.add_item(reward.quest_title)
	%Chapters.select(selected_quest)
	_refresh()

func _refresh() -> void:
	var reward := _rewards[selected_quest]
	var quests: Dictionary = _state.quests
	var status: Dictionary = quests.get(reward.quest_id, {})
	var prerequisite: Dictionary = quests.get(reward.prerequisite_id, {})
	var quest: int = status.get("quest", LunexProgressStore.Quest.AVAILABLE)
	if not reward.prerequisite_id.is_empty() and prerequisite.get("quest") != LunexProgressStore.Quest.COMPLETE:
		quest = LunexProgressStore.Quest.LOCKED
	var item: String = status.get("item", "")
	var equipped: String = status.get("equipped", "")
	%Quest.text = ["Доступно", reward.objective, "Завершено", "Сначала завершите предыдущее задание"][quest]
	var level := 2 if _state.experience >= _level_two_experience else 1
	%Experience.text = "Уровень %d · Опыт %d" % [level, _state.experience]
	%Item.text = "Награда: %s · %d опыта" % [reward.item_name, reward.experience]
	var slots := PackedStringArray()
	for definition in _rewards:
		var row: Dictionary = quests.get(definition.quest_id, {})
		var equipped_item: String = row.get("equipped", "")
		slots.append("%s: %s" % [definition.slot_name, definition.item_name if equipped_item == definition.item_id else (equipped_item if not equipped_item.is_empty() else "пусто")])
	%Slot.text = "\n".join(slots)
	%Accept.disabled = quest != LunexProgressStore.Quest.AVAILABLE
	%Equip.disabled = item.is_empty() or equipped == item
