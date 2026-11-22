extends LunexVirtualJoystick

var _applied_inset := Vector2.ZERO

func _ready() -> void:
	super._ready()
	_place_in_safe_area()
	get_viewport().size_changed.connect(_place_in_safe_area)

func _notification(what: int) -> void:
	if is_node_ready() and what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_reset()
	if is_node_ready() and what == NOTIFICATION_APPLICATION_RESUMED:
		_place_in_safe_area()

func _place_in_safe_area() -> void:
	var inset := Vector2.ZERO
	if OS.has_feature("android"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var viewport_size := get_viewport_rect().size
		if safe.has_area() and screen.x > 0 and screen.y > 0:
			inset = Vector2(safe.position.x, screen.y - safe.end.y).max(Vector2.ZERO)
			inset *= viewport_size / Vector2(screen)
	var change := inset - _applied_inset
	offset_left += change.x
	offset_right += change.x
	offset_top -= change.y
	offset_bottom -= change.y
	_applied_inset = inset
