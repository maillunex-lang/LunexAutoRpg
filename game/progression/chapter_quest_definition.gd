class_name LunexChapterQuestDefinition
extends Resource

@export var quest_id := ""
@export var prerequisite_id := ""
@export var npc_id := ""
@export var objective_npc_id := ""
@export_range(1, 1000) var objective_goal := 1
@export var title := ""
@export_multiline var objective_description := ""
