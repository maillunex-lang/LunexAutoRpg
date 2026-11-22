class_name LunexProgressHUD
extends Control

signal accept_requested
signal equip_requested

func _ready() -> void:
	%Progress.pressed.connect(func() -> void: %Panel.visible = not %Panel.visible)
	%Close.pressed.connect(func() -> void: %Panel.hide())
	%Accept.pressed.connect(func() -> void: accept_requested.emit())
	%Equip.pressed.connect(func() -> void: equip_requested.emit())
	reset()

func reset() -> void:
	%Panel.hide()
	%Progress.disabled = true

func show_state(state: Dictionary, reward: LunexQuestReward) -> void:
	%Progress.disabled = false
	%Title.text = reward.quest_title
	%Quest.text = ["Доступно", "Победите тренировочную цель", "Завершено"][int(state.quest)]
	%Experience.text = "Опыт: %d" % state.experience
	%Item.text = "Предмет: %s" % (reward.item_name if state.item == reward.item_id else str(state.item)) if state.item != "" else "Инвентарь пуст"
	%Slot.text = "Слот: %s" % (reward.item_name if state.equipped == reward.item_id else str(state.equipped)) if state.equipped != "" else "Слот пуст"
	%Accept.disabled = state.quest != LunexProgressStore.Quest.AVAILABLE
	%Equip.disabled = state.item == "" or state.equipped == state.item
