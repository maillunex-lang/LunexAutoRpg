extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
    if condition:
        print("PASS: ", label)
        return true
    push_error("FAIL: " + label)
    quit(1)
    return false

func _run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        quit(2)
        return
    var store := LunexProgressStore.new()
    if not _check(store.open(args[0]), "SQLite opens with chapter quest schema"):
        return
    var a := "stage763_a"
    var b := "stage763_b"
    store.load_profile(a)
    store.load_profile(b)
    if not _check(not store.chapter_accept(a, "second", "first"), "prerequisite blocks premature quest"):
        return
    if not _check(store.chapter_accept(a, "first"), "first profile accepts quest"):
        return
    if not _check(not store.chapter_accept(a, "first"), "duplicate acceptance rejected"):
        return
    if not _check(not store.chapter_complete(a, "first", 2), "incomplete objective cannot finish"):
        return
    if not _check(not store.chapter_advance(a, "first", 999, 2), "arbitrary client progress rejected"):
        return
    if not _check(store.chapter_advance(a, "first", 1, 2) and store.chapter_advance(a, "first", 1, 2), "verified progress reaches goal"):
        return
    if not _check(not store.chapter_advance(a, "first", 1, 2), "objective cannot overflow goal"):
        return
    if not _check(store.chapter_complete(a, "first", 2), "completed objective transitions once"):
        return
    if not _check(not store.chapter_complete(a, "first", 2), "repeat completion rejected"):
        return
    if not _check(store.chapter_accept(a, "second", "first"), "completed prerequisite unlocks next quest"):
        return
    if not _check(not store.chapter_accept(b, "second", "first"), "prerequisite isolated by profile"):
        return
    var state := store.read_profile(a)
    if not _check(state.chapter_quests.first.state == 2 and state.chapter_quests.first.count == 2 and state.chapter_quests.second.state == 1, "server state contains persisted progress"):
        return
    if not _check(store.read_profile(b).chapter_quests.is_empty(), "other player has no leaked progress"):
        return
    store = null
    var reloaded := LunexProgressStore.new()
    if not _check(reloaded.open(args[0]) and reloaded.read_profile(a).chapter_quests.first.state == 2, "progress persists after reopening SQLite"):
        return
    var chain := ["first_steps", "supplies", "courtyard_report", "scout_contact", "passage_report"]
    var previous := ""
    for quest_id in chain:
        if not _check(reloaded.chapter_accept(b, quest_id, previous), "chain accepts " + quest_id):
            return
        if not _check(reloaded.chapter_advance(b, quest_id, 1, 1) and reloaded.chapter_complete(b, quest_id, 1), "chain completes " + quest_id):
            return
        previous = quest_id
    if not _check(reloaded.read_profile(b).chapter_quests.size() == 5, "all five chained quests persisted"):
        return
    quit()
