extends "res://tests/stage02_smoke.gd"
## Run prepare and reload against separate server processes using the same test database.

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3 or OS.get_environment("LUNEX_TEST_PROFILE").length() != 64:
		quit(2)
		return
	var address := args[0]
	var port := args[1].to_int()
	var fighter := _client("Fighter")
	fighter._profile_token = OS.get_environment("LUNEX_TEST_PROFILE")
	_join(fighter, address, port, "Trainee")
	if args[2] == "reload":
		if await _expect("experience, quest, item and slot survive server restart", func() -> bool:
			return _equipped(fighter)
		):
			fighter.screen.disconnect_requested.emit()
			quit()
		return
	if args[2] != "prepare":
		quit(2)
		return
	var observer := _client("Observer")
	_join(observer, address, port, "Observer")
	if not await _expect("both profiles start with an available quest", func() -> bool:
		return _training(fighter).get("quest", -1) == 0 and _training(observer).get("quest", -1) == 0
	):
		return
	fighter.progress_hud.equip_requested.emit()
	fighter.progress_hud.accept_requested.emit()
	if not await _expect("accepting quest changes only the requesting profile", func() -> bool:
		return _training(fighter).get("quest", -1) == 1 and _training(fighter).equipped == "" and _training(observer).quest == 0
	):
		return
	fighter.combat.selected = true
	fighter.combat.auto_requested.emit(true)
	if not await _expect("victory grants one item and experience", func() -> bool:
		return _training(fighter).get("quest", -1) == 2 and _training(fighter).experience == 25 and _training(fighter).item == "training_ring"
	):
		return
	fighter.progress_hud.equip_requested.emit()
	if not await _expect("server equips the earned item", func() -> bool: return _equipped(fighter)):
		return
	if not await _expect("enemy respawns for a repeat victory", func() -> bool: return fighter.enemy.health > 0):
		return
	fighter.progress_hud.accept_requested.emit()
	fighter.combat.auto_requested.emit(true)
	if not await _expect("repeat victory reaches zero enemy health", func() -> bool: return fighter.enemy.health == 0):
		return
	fighter.screen.disconnect_requested.emit()
	if not await _expect("departed player disappears", func() -> bool: return observer.players.get_child_count() == 1):
		return
	_join(fighter, address, port, "Renamed")
	if not await _expect("reconnect preserves a single award and slot; observer received nothing", func() -> bool:
		return _equipped(fighter) and _training(observer).quest == 0 and _training(observer).experience == 0 and _training(observer).item == ""
	):
		return
	fighter.screen.disconnect_requested.emit()
	observer.screen.disconnect_requested.emit()
	quit()

func _equipped(client: Node) -> bool:
	var state: Dictionary = _training(client)
	return state.get("quest", -1) == 2 and state.experience == 25 and state.item == "training_ring" and state.equipped == state.item
