class_name LunexNpcDialogueDefinition
extends Resource

@export var npc_id: String = ""
@export_multiline var dialogue_text: String = ""

func is_valid_definition() -> bool:
	return not npc_id.is_empty() and dialogue_text.begins_with("~ start")
