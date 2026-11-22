class_name LunexCombatHUD
extends Control

signal attack_requested
signal auto_requested(enabled: bool)

var selected := false
var target_index := 0
var targets: Array[LunexTrainingEnemy] = []

func _ready() -> void:
	%Target.pressed.connect(_cycle_target)
	%Attack.pressed.connect(func() -> void: attack_requested.emit())
	%Auto.toggled.connect(func(enabled: bool) -> void: auto_requested.emit(enabled))

func refresh(auto_active: bool) -> void:
	var target := targets[target_index]
	%Target.text = target.target_name if selected else "Выбрать цель"
	%Health.text = ("%d / %d ОЗ" % [target.health, target.max_health]) if target.health > 0 else "Цель повержена"
	%Attack.disabled = not selected or target.health <= 0
	%Auto.disabled = (not selected or target.health <= 0) and not auto_active
	%Auto.set_pressed_no_signal(auto_active)
	%Auto.text = "Стоп" if auto_active else "Авто"

func _cycle_target() -> void:
	for offset in range(targets.size()):
		var next := (target_index + offset + int(selected)) % targets.size()
		if targets[next].health > 0:
			if selected and next != target_index:
				auto_requested.emit(false)
			target_index = next
			selected = true
			return
