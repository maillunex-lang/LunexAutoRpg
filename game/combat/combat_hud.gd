class_name LunexCombatHUD
extends Control

signal attack_requested
signal auto_requested(enabled: bool)
signal skill_requested(ability_id: String)
var _skill_ids := ["", ""]

var zone_id := 0
var selected := false
var target_index := 0
var targets: Array[LunexTrainingEnemy] = []

func _ready() -> void:
	%Target.pressed.connect(_cycle_target)
	%Attack.pressed.connect(func() -> void: attack_requested.emit())
	%Auto.toggled.connect(func(enabled: bool) -> void: auto_requested.emit(enabled))
	%SkillOne.pressed.connect(func() -> void: skill_requested.emit(_skill_ids[0]))
	%SkillTwo.pressed.connect(func() -> void: skill_requested.emit(_skill_ids[1]))

func refresh(player: LunexNetworkPlayer) -> void:
	var auto_active := player.auto_enabled
	var alive := player.health > 0
	%HeroHealth.max_value = player.max_health
	%HeroHealth.value = player.health
	%HeroStatus.text = "Герой: %d / %d ОЗ" % [player.health, player.max_health] if alive else "Возрождение: %d с" % ceili(player.revival_left)
	var target := targets[target_index]
	%Target.text = target.target_name if selected else "Выбрать цель"
	%Health.text = ("%d / %d ОЗ" % [target.health, target.max_health]) if target.health > 0 else "Цель повержена"
	%Attack.disabled = not alive or not selected or target.health <= 0
	%Auto.disabled = (not alive or not selected or target.health <= 0) and not auto_active
	%Auto.set_pressed_no_signal(auto_active)
	%Auto.text = "Стоп" if auto_active else "Авто"

func refresh_skills(class_id: String, experience: int, energy: float) -> void:
	var ids := ["warrior_strike", "warrior_shield"] if class_id == "warrior" else ["mage_bolt", "mage_fireball"] if class_id == "mage" else ["", ""]
	_skill_ids = ids
	var level := 2 if experience >= 50 else 1
	for index in range(2):
		var button: Button = %SkillOne if index == 0 else %SkillTwo
		if ids[index].is_empty():
			button.hide()
			continue
		var skill: LunexAbilityDefinition = load("res://game/combat/abilities/" + ids[index] + ".tres")
		button.show()
		button.text = {"warrior_strike": "Мощный удар", "warrior_shield": "Щит", "mage_bolt": "Магический снаряд", "mage_fireball": "Огненный шар"}.get(ids[index], ids[index])
		button.disabled = skill == null or skill.unlock_level > level or energy < skill.resource_cost
		if skill != null and skill.unlock_level > level:
			button.text += " (ур. %d)" % skill.unlock_level
	%Energy.text = "Энергия: %d / 100" % int(energy)

func show_skill_feedback(message: String) -> void:
	%SkillNotice.text = "Навык: " + message

func enter_zone(next_zone: int, first_target: int) -> void:
	zone_id = next_zone
	target_index = first_target
	selected = false

func _cycle_target() -> void:
	for offset in range(targets.size()):
		var next := (target_index + offset + int(selected)) % targets.size()
		if targets[next].zone_id == zone_id and targets[next].health > 0:
			if selected and next != target_index:
				auto_requested.emit(false)
			target_index = next
			selected = true
			return
