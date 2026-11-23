extends SceneTree

var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func require_condition(condition: bool, name: String) -> bool:
	if not condition:
		push_error("FAIL: " + name)
		quit(1)
		return false
	checks += 1
	print("PASS: ", name)
	return true

func _run() -> void:
	var preset: LunexHudLayoutPreset = load("res://game/mobile/hud_layout_preset.tres")
	if not require_condition(preset != null, "Godot native .tres preset loads"): return
	if not require_condition(is_equal_approx(preset.normalized_scale(2.0), 1.35), "Scale upper safety bound"): return
	if not require_condition(is_equal_approx(preset.normalized_scale(0.2), 0.65), "Scale lower safety bound"): return
	var editor: LunexHudLayoutEditor = load("res://game/mobile/hud_layout_editor.tscn").instantiate()
	root.add_child(editor)
	await process_frame
	if not require_condition(editor.layout_preset == preset or editor.layout_preset != null, "Inspector-configured preset exists"): return
	if not require_condition(is_equal_approx(editor.action_slider.value, 1.0), "Initial action scale"): return
	var updates := [0]
	editor.layout_changed.connect(func(_a: float, _j: float) -> void: updates[0] += 1)
	editor.action_slider.value = 1.25
	if not require_condition(updates[0] == 1, "Change signal fires"): return
	if not require_condition(editor.action_label.text == "Кнопки: 125%", "Label reflects changed scale"): return
	editor.reset_to_preset()
	if not require_condition(is_equal_approx(editor.action_slider.value, 1.0), "Preset reset restores scale"): return
	if not require_condition(editor.has_node("Panel/Options/JoystickScale"), "Godot-editor editable UI scene"): return
	editor.queue_free()
	print("STAGE815_TOTAL=", checks)
	quit()
