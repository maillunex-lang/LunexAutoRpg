extends "res://tests/stage02_smoke.gd"

func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var manager = load("res://addons/dialogue_manager/dialogue_manager.gd").new()
    manager.name = "DialogueManager"
    root.add_child(manager)
    var first := _client("First")
    var second := _client("Second")
    _join(first, args[0], args[1].to_int(), "First")
    _join(second, args[0], args[1].to_int(), "Second")
    if not await _expect("two clients join and NPCs are editable instances", func() -> bool:
        return first.players.get_child_count() == 2 and second.players.get_child_count() == 2 and first.npcs.get_child_count() == 3
    ):
        return
    first._request_npc.rpc_id(1, "mentor")
    if not await _expect("nearby NPC interaction reaches only the requesting client", func() -> bool:
        return first.dialogue_window.visible and first.dialogue_window.speaker.text == "Наставник" and not second.dialogue_window.visible
    ):
        return
    var dialogue = first.dialogue_window
    if not await _expect("dialogue continues to a branch with two choices", func() -> bool:
        return dialogue.choices.get_child_count() == 1
    ):
        return
    dialogue.choices.get_child(0).pressed.emit()
    if not await _expect("two editable response choices appear", func() -> bool:
        return dialogue.choices.get_child_count() == 2
    ):
        return
    dialogue.choices.get_child(0).pressed.emit()
    if not await _expect("selected response changes the dialogue text", func() -> bool:
        return dialogue.body.text.contains("тренироваться")
    ):
        return
    dialogue.close_dialogue()
    first.zone_hud.notice.hide()
    first._request_npc.rpc_id(1, "scout")
    if not await _expect("cross-zone NPC interaction is denied", func() -> bool:
        return first.zone_hud.notice.visible and first.zone_hud.notice.text.contains("Подойдите")
    ):
        return
    second._request_npc.rpc_id(1, "mentor")
    if not await _expect("second profile independently interacts with NPC", func() -> bool:
        return second.dialogue_window.visible and second.dialogue_window.speaker.text == "Наставник"
    ):
        return
    quit()
