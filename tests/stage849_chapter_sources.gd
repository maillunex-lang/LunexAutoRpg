extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var chapters := [1, 2, 3, 4, 6, 7]
	var seen := {}
	for n in chapters:
		var definition := load("res://game/progression/chapter_%d.tres" % n) as LunexChapterQuestDefinition
		if definition == null:
			push_error("Missing chapter")
			quit(1)
			return
		var item := LunexItemCatalog.find(definition.reward_item_id)
		if item == null or seen.has(item.slot):
			push_error("Missing or duplicate item source chapter " + str(n))
			quit(1)
			return
		seen[item.slot] = true
	if seen.size() != 6:
		push_error("Incomplete item sources")
		quit(1)
		return
	print("STAGE849_SOURCES=PASS six_slots_in_existing_chapter_rewards")
	quit(0)
