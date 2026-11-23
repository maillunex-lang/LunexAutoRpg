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
    if not await _expect("five chained quest resources loaded", func() -> bool:
        return first.chapter_quest_definitions.size() == 5 and first.chapter_quest_definitions[4].prerequisite_id == "scout_contact"
    ):
        return
    if not await _expect("mentor dialogue offers first quest", func() -> bool:
        return first.dialogue_window.get_node("%QuestActions").get_child_count() == 1
    ):
        return
    first.dialogue_window.get_node("%QuestActions").get_child(0).pressed.emit()
    if not await _expect("server accepts first quest and syncs state", func() -> bool:
        return first._progress.get("chapter_quests", {}).has("first_steps")
    ):
        return
    if not await _expect("journal shows five chapter entries and route is enabled", func() -> bool:
        return first.progress_hud.get_node("%ChapterList").item_count == 5 and not first.progress_hud.get_node("%ChapterRoute").disabled
    ):
        return
    second._request_quest_route.rpc_id(1, "first_steps")
    await create_timer(0.3).timeout
    if not await _expect("inactive profile cannot start a route", func() -> bool:
        return not second.zone_hud.notice.visible
    ):
        return
    first.progress_hud.get_node("%ChapterRoute").pressed.emit()
    if not await _expect("active chapter starts server-controlled NPC navigation", func() -> bool:
        return first.zone_hud.notice.visible and first.zone_hud.notice.text.contains("Автопуть")
    ):
        return
    if not await _expect("server navigation moves the hero toward the quest NPC", func() -> bool:
        var hero := first.players.get_node(str(first.multiplayer.get_unique_id())) as LunexNetworkPlayer
        return hero.global_position.x > -1.7
    ):
        return
    if not await _expect("other profile has no first quest", func() -> bool:
        return not second._progress.get("chapter_quests", {}).has("first_steps")
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
