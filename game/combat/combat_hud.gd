class_name LunexCombatHUD
extends Control

signal attack_requested
signal auto_requested(enabled: bool)

var selected := false

func _ready() -> void:
	%Target.pressed.connect(_toggle_target)
	%Attack.pressed.connect(func() -> void: attack_requested.emit())
	%Auto.toggled.connect(func(enabled: bool) -> void: auto_requested.emit(enabled))

func refresh(enemy: LunexTrainingEnemy, auto_active: bool) -> void:
	%Target.text = "Цель выбрана" if selected else "Выбрать цель"
	%Health.text = ("%d / %d ОЗ" % [enemy.health, enemy.max_health]) if enemy.health > 0 else "Цель повержена"
	%Attack.disabled = not selected or enemy.health <= 0
	%Auto.disabled = (not selected or enemy.health <= 0) and not auto_active
	%Auto.set_pressed_no_signal(auto_active)
	%Auto.text = "Стоп" if auto_active else "Авто"


func _toggle_target() -> void:
	selected = not selected
	if not selected:
		auto_requested.emit(false)
