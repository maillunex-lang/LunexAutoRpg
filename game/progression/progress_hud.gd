class_name LunexProgressHUD
extends Control

signal accept_requested
signal equip_requested
signal quest_route_requested(quest_id: String)

var selected_quest := 0
var _state: Dictionary = {}
var _rewards: Array[LunexQuestReward] = []
var _level_two_experience := 50
var _chapter_definitions: Array[LunexChapterQuestDefinition] = []

func _ready() -> void:
	%Progress.pressed.connect(func() -> void: %Panel.visible = not %Panel.visible)
	%Close.pressed.connect(func() -> void: %Panel.hide())
	%Accept.pressed.connect(func() -> void: accept_requested.emit())
	%Equip.pressed.connect(func() -> void: equip_requested.emit())
	%ChapterRoute.pressed.connect(func() -> void:
		var idx: int = %ChapterList.get_selected_items()[0] if not %ChapterList.get_selected_items().is_empty() else -1
		if idx >= 0 and idx < _chapter_definitions.size():
			quest_route_requested.emit(_chapter_definitions[idx].quest_id)
	)
	%ChapterList.item_selected.connect(func(_idx: int) -> void: _refresh_chapters())
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

func show_state(state: Dictionary, rewards: Array[LunexQuestReward], level_two_experience: int, chapters: Array[LunexChapterQuestDefinition] = []) -> void:
	_state = state
	_rewards = rewards
	_chapter_definitions = chapters
	_level_two_experience = level_two_experience
	%Progress.disabled = false
	%Chapters.clear()
	for reward in rewards:
		%Chapters.add_item(reward.quest_title)
	%Chapters.select(selected_quest)
	_refresh()
	_refresh_chapters()

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
	%Item.text = "Награда: %d опыта" % reward.experience if reward.item_id.is_empty() else "Награда: %s · %d опыта" % [reward.item_name, reward.experience]
	var slots := PackedStringArray()
	for definition in _rewards:
		if definition.slot_name.is_empty():
			continue
		var row: Dictionary = quests.get(definition.quest_id, {})
		var equipped_item: String = row.get("equipped", "")
		slots.append("%s: %s" % [definition.slot_name, definition.item_name if equipped_item == definition.item_id else (equipped_item if not equipped_item.is_empty() else "пусто")])
	%Slot.text = "\n".join(slots)
	%Accept.disabled = quest != LunexProgressStore.Quest.AVAILABLE
	%Equip.disabled = item.is_empty() or equipped == item


func _refresh_chapters() -> void:
	var list: ItemList = %ChapterList
	var previous: int = list.get_selected_items()[0] if not list.get_selected_items().is_empty() else 0
	list.clear()
	var states: Dictionary = _state.get("chapter_quests", {})
	for definition in _chapter_definitions:
		var state: Dictionary = states.get(definition.quest_id, {})
		var status := int(state.get("state", 0))
		var locked := not definition.prerequisite_id.is_empty() and int(states.get(definition.prerequisite_id, {}).get("state", 0)) != 2
		var prefix := "✓ " if status == 2 else ("▶ " if status == 1 else ("🔒 " if locked else "○ "))
		list.add_item(prefix + definition.title)
	if list.item_count == 0:
		%ChapterDetail.text = "Сюжетных заданий нет."
		%ChapterRoute.disabled = true
		return
	list.select(clampi(previous, 0, list.item_count - 1))
	var selected: LunexChapterQuestDefinition = _chapter_definitions[list.get_selected_items()[0]]
	var state: Dictionary = states.get(selected.quest_id, {})
	var status := int(state.get("state", 0))
	%ChapterDetail.text = selected.objective_description + ("
Завершено" if status == 2 else ("
Выполняется" if status == 1 else "
Не принято"))
	%ChapterRoute.disabled = status != 1
