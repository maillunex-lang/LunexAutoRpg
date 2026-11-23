class_name LunexProgressHUD
extends Control

signal accept_requested
signal equip_requested
signal quest_route_requested(quest_id: String)
signal chapter_equip_requested(quest_id: String)
signal upgrade_requested(item_id: String)
signal inventory_equip_requested(item_id: String)

var selected_quest := 0
var _state: Dictionary = {}
var _rewards: Array[LunexQuestReward] = []
var _level_two_experience := 50
var _chapter_definitions: Array[LunexChapterQuestDefinition] = []

func _ready() -> void:
	%Progress.pressed.connect(func() -> void: %Panel.visible = not %Panel.visible)
	%Inventory.pressed.connect(func() -> void:
		%Panel.hide()
		%InventoryPanel.visible = not %InventoryPanel.visible
	)
	%InventoryClose.pressed.connect(func() -> void: %InventoryPanel.hide())
	%InventoryItems.item_selected.connect(func(_idx: int) -> void: _refresh_inventory_selection())
	%InventoryEquip.pressed.connect(func() -> void:
		var item_id := _selected_inventory_item()
		if not item_id.is_empty():
			inventory_equip_requested.emit(item_id)
	)
	%InventoryUpgrade.pressed.connect(func() -> void:
		var item_id := _selected_inventory_item()
		if not item_id.is_empty():
			upgrade_requested.emit(item_id)
	)
	%Close.pressed.connect(func() -> void: %Panel.hide())
	%Accept.pressed.connect(func() -> void: accept_requested.emit())
	%Equip.pressed.connect(func() -> void: equip_requested.emit())
	%ChapterRoute.pressed.connect(func() -> void:
		var idx: int = %ChapterList.get_selected_items()[0] if not %ChapterList.get_selected_items().is_empty() else -1
		if idx >= 0 and idx < _chapter_definitions.size():
			quest_route_requested.emit(_chapter_definitions[idx].quest_id)
	)
	%ChapterEquip.pressed.connect(func() -> void:
		var idx: int = %ChapterList.get_selected_items()[0] if not %ChapterList.get_selected_items().is_empty() else -1
		if idx >= 0 and idx < _chapter_definitions.size():
			chapter_equip_requested.emit(_chapter_definitions[idx].quest_id)
	)
	%UpgradeItem.pressed.connect(func() -> void:
		var idx: int = %ChapterList.get_selected_items()[0] if not %ChapterList.get_selected_items().is_empty() else -1
		if idx >= 0 and idx < _chapter_definitions.size():
			var item_id: String = _chapter_definitions[idx].reward_item_id
			if not item_id.is_empty():
				upgrade_requested.emit(item_id)
	)
	%ChapterList.item_selected.connect(func(_idx: int) -> void: _refresh_chapters())
	%Chapters.item_selected.connect(func(index: int) -> void:
		selected_quest = index
		_refresh()
	)
	reset()

func reset() -> void:
	%Panel.hide()
	%InventoryPanel.hide()
	%Inventory.disabled = true
	%Progress.disabled = true
	selected_quest = 0
	_state.clear()

func show_state(state: Dictionary, rewards: Array[LunexQuestReward], level_two_experience: int, chapters: Array[LunexChapterQuestDefinition] = []) -> void:
	_state = state
	_rewards = rewards
	_chapter_definitions = chapters
	_level_two_experience = level_two_experience
	%Progress.disabled = false
	%Inventory.disabled = false
	%Chapters.clear()
	for reward in rewards:
		%Chapters.add_item(reward.quest_title)
	%Chapters.select(selected_quest)
	_refresh()
	_refresh_chapters()
	_refresh_inventory()

func _selected_inventory_item() -> String:
	var indices: PackedInt32Array = %InventoryItems.get_selected_items()
	if indices.is_empty():
		return ""
	var inventory: Array = _state.get("inventory", [])
	var idx: int = indices[0]
	return str(inventory[idx].get("item_id", "")) if idx >= 0 and idx < inventory.size() else ""

static func item_display_name(item_id: String) -> String:
	var definition := LunexItemCatalog.find(item_id)
	return definition.display_name if definition != null else item_id

static func slot_display_name(slot_id: String) -> String:
	return {
		"weapon": "Оружие",
		"armor": "Броня",
		"helmet": "Шлем",
		"gloves": "Перчатки",
		"boots": "Обувь",
		"accessory": "Аксессуар"
	}.get(slot_id, slot_id)

static func rarity_display_name(rarity: int) -> String:
	return {
		1: "Обычный",
		2: "Редкий",
		3: "Эпический",
		4: "Легендарный",
		5: "Мифический"
	}.get(rarity, "Неизвестный")

func _refresh_inventory() -> void:
	var list: ItemList = %InventoryItems
	var selected_id := _selected_inventory_item()
	list.clear()
	var inventory: Array = _state.get("inventory", [])
	for row in inventory:
		var item_id: String = str(row.get("item_id", ""))
		var rarity: int = int(row.get("rarity", 1))
		var level: int = int(row.get("upgrade_level", 0))
		list.add_item("%s · %s · %s · +%d" % [item_display_name(item_id), slot_display_name(str(row.get("slot", ""))), rarity_display_name(rarity), level])
		if item_id == selected_id:
			list.select(list.item_count - 1)
	if list.item_count > 0 and list.get_selected_items().is_empty():
		list.select(0)
	var equipped: Dictionary = _state.get("equipped_slots", {})
	var lines: PackedStringArray = []
	for slot in LunexProgressStore.EQUIPMENT_SLOTS:
		lines.append("%s: %s" % [slot_display_name(slot), item_display_name(str(equipped[slot])) if equipped.has(slot) and not str(equipped[slot]).is_empty() else "пусто"])
	%InventorySlots.text = "GS: %d · Золото: %d\n%s" % [int(_state.get("gear_score", 0)), int(_state.get("gold", 0)), " | ".join(lines)]
	_refresh_inventory_selection()

func _refresh_inventory_selection() -> void:
	var item_id := _selected_inventory_item()
	%InventoryEquip.disabled = item_id.is_empty()
	%InventoryUpgrade.disabled = item_id.is_empty()
	if item_id.is_empty():
		%InventoryInfo.text = "Рюкзак пуст. Получай предметы за задания."
		return
	for row in _state.get("inventory", []):
		if str(row.get("item_id", "")) == item_id:
			var rarity: int = int(row.get("rarity", 1))
			var level: int = int(row.get("upgrade_level", 0))
			var cost: int = (level + 1) * 50
			var score: int = LunexProgressStore.gear_score_for_item(rarity, level)
			%InventoryInfo.text = "%s | %s | %s | GS %d | улучшение: %d золота" % [item_display_name(item_id), slot_display_name(str(row.get("slot", ""))), rarity_display_name(rarity), score, cost]
			%InventoryUpgrade.disabled = level >= 15 or int(_state.get("gold", 0)) < cost
			%InventoryEquip.disabled = str(_state.get("equipped_slots", {}).get(str(row.get("slot", "")), "")) == item_id
			return

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
	%Experience.text = "Уровень %d · Опыт %d · Золото %d" % [level, _state.experience, int(_state.get("gold", 0))]
	%Item.text = "Награда: %d опыта" % reward.experience if reward.item_id.is_empty() else "Награда: %s · %d опыта" % [reward.item_name, reward.experience]
	var slots := PackedStringArray()
	for definition in _rewards:
		if definition.slot_name.is_empty():
			continue
		var row: Dictionary = quests.get(definition.quest_id, {})
		var equipped_item: String = row.get("equipped", "")
		slots.append("%s: %s" % [definition.slot_name, definition.item_name if equipped_item == definition.item_id else (equipped_item if not equipped_item.is_empty() else "пусто")])
	var equipment: Dictionary = _state.get("equipped_slots", {})
	for slot_id in LunexProgressStore.EQUIPMENT_SLOTS:
		slots.append("%s: %s" % [slot_id, str(equipment.get(slot_id, "пусто"))])
	%Slot.text = "GS: %d\n%s" % [int(_state.get("gear_score", 0)), "\n".join(slots)]
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
	var status_hint := "Завершено" if status == 2 else ("Выполняется" if status == 1 else "Не принято")
	%ChapterDetail.text = (selected.story_intro + "\n\n" if not selected.story_intro.is_empty() else "") + selected.objective_description + "\n" + status_hint
	var prerequisite_ready: bool = selected.prerequisite_id.is_empty() or int(states.get(selected.prerequisite_id, {}).get("state", 0)) == 2
	var available: bool = status == 0 and prerequisite_ready
	%ChapterRoute.disabled = status != 1 and not available
	%ChapterRoute.text = "К персонажу за заданием" if available else "Автопуть к цели"
	var reward: Dictionary = _state.get("quests", {}).get("chapter:" + selected.quest_id, {})
	var owned: String = reward.get("item", "")
	%ChapterEquip.disabled = owned.is_empty() or reward.get("equipped", "") == owned
	%UpgradeItem.disabled = owned.is_empty()
	%ChapterDetail.text += "\nНаграда: %d опыта%s" % [selected.reward_experience, " + " + selected.reward_item_id if not selected.reward_item_id.is_empty() else ""]
