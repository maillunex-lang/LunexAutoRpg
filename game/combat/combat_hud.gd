class_name LunexCombatHUD
extends Control

signal attack_requested
signal auto_requested(enabled: bool)
signal skill_requested(ability_id: String)
var _skill_ids := ["", ""]
# Client countdown is cosmetic; server remains authoritative.
var _local_cooldown_end: Dictionary = {}
var _vfx_tween: Tween

var zone_id := 0
var selected := false
var target_index := 0
var targets: Array[LunexTrainingEnemy] = []
var _last_player: LunexNetworkPlayer

func _ready() -> void:
	%Target.pressed.connect(_cycle_target)
	%Attack.pressed.connect(_attack_pressed)
	%Auto.toggled.connect(func(enabled: bool) -> void: auto_requested.emit(enabled))
	%SkillOne.pressed.connect(func() -> void: skill_requested.emit(_skill_ids[0]))
	%SkillTwo.pressed.connect(func() -> void: skill_requested.emit(_skill_ids[1]))

func refresh(player: LunexNetworkPlayer) -> void:
	_last_player = player
	var auto_active := player.auto_enabled
	var alive := player.health > 0
	%HeroHealth.max_value = player.max_health
	%HeroHealth.value = player.health
	%HeroStatus.text = "Герой: %d / %d ОЗ" % [player.health, player.max_health] if alive else "Возрождение: %d с" % ceili(player.revival_left)
	if targets.is_empty():
		%Attack.disabled = true
		%Auto.disabled = true
		return
	var target := targets[target_index]
	%Target.text = target.target_name if selected else "Выбрать цель"
	%Health.text = ("%d / %d ОЗ" % [target.health, target.max_health]) if target.health > 0 else "Цель повержена"
	%Attack.disabled = not alive or not _has_living_target()
	%Auto.disabled = (not alive or not selected or target.health <= 0) and not auto_active
	%Auto.set_pressed_no_signal(auto_active)
	%Auto.text = "Стоп" if auto_active else "Авто"

func refresh_skills(class_id: String, experience: int, energy: float) -> void:
	var ids := ["warrior_strike", "warrior_shield"] if class_id == "warrior" else ["mage_bolt", "mage_fireball"] if class_id == "mage" else ["priest_heal", "priest_blessing"] if class_id == "priest" else ["bard_song", "bard_restore"] if class_id == "bard" else ["", ""]
	_skill_ids = ids
	var level := 2 if experience >= 50 else 1
	for index in range(2):
		var button: Button = %SkillOne if index == 0 else %SkillTwo
		if ids[index].is_empty():
			button.hide()
			continue
		var skill: LunexAbilityDefinition = load("res://game/combat/abilities/" + ids[index] + ".tres")
		button.show()
		button.text = {"warrior_strike": "Мощный удар", "warrior_shield": "Щит", "mage_bolt": "Магический снаряд", "mage_fireball": "Огненный шар", "priest_heal": "Исцеление", "priest_blessing": "Благословение", "bard_song": "Боевая песня", "bard_restore": "Восстановление"}.get(ids[index], ids[index])
		var remaining := maxf(0.0, (int(_local_cooldown_end.get(ids[index], 0)) - Time.get_ticks_msec()) / 1000.0)
		button.disabled = skill == null or skill.unlock_level > level or energy < skill.resource_cost or remaining > 0.0
		if remaining > 0.0:
			button.text += " %.1fс" % remaining
		if skill != null and skill.unlock_level > level:
			button.text += " (ур. %d)" % skill.unlock_level
	%Energy.text = "Энергия: %d / 100" % int(energy)

func show_skill_feedback(message: String, cooldown_ms: int = 0) -> void:
	%SkillNotice.text = "Навык: " + message
	if not message.begins_with("ok:"):
		return
	var id := message.trim_prefix("ok:")
	if id not in _skill_ids:
		return
	_local_cooldown_end[id] = Time.get_ticks_msec() + maxi(cooldown_ms, 0)
	# Lightweight procedural HUD pulse: no textures, particles or additional draw calls per frame.
	if is_instance_valid(_vfx_tween) and _vfx_tween.is_running():
		_vfx_tween.kill()
	%SkillFlash.color = Color(0.35, 0.7, 1.0, 0.24) if id.begins_with("mage") or id.begins_with("priest") else Color(1.0, 0.7, 0.2, 0.24)
	%SkillFlash.show()
	_vfx_tween = create_tween()
	_vfx_tween.tween_property(%SkillFlash, "modulate:a", 0.0, 0.35).from(1.0)
	_vfx_tween.tween_callback(func() -> void: %SkillFlash.hide())

func reset_skill_ui() -> void:
	_local_cooldown_end.clear()
	if is_instance_valid(_vfx_tween):
		_vfx_tween.kill()
	%SkillFlash.hide()
	%SkillFlash.modulate.a = 1.0

func enter_zone(next_zone: int, first_target: int) -> void:
	zone_id = next_zone
	target_index = first_target
	selected = false

func _has_living_target() -> bool:
	for candidate in targets:
		if candidate.zone_id == zone_id and candidate.health > 0:
			return true
	return false

func _attack_pressed() -> void:
	if not selected or targets[target_index].health <= 0:
		var best := -1
		var best_distance := INF
		for index in range(targets.size()):
			var candidate := targets[index]
			if candidate.zone_id != zone_id or candidate.health <= 0:
				continue
			var distance := _last_player.global_position.distance_squared_to(candidate.global_position) if is_instance_valid(_last_player) else float(index)
			if distance < best_distance:
				best_distance = distance
				best = index
		if best < 0:
			return
		target_index = best
		selected = true
	attack_requested.emit()

func _cycle_target() -> void:
	for offset in range(targets.size()):
		var next := (target_index + offset + int(selected)) % targets.size()
		if targets[next].zone_id == zone_id and targets[next].health > 0:
			if selected and next != target_index:
				auto_requested.emit(false)
			target_index = next
			selected = true
			return
