class_name LunexDialogueWindow
extends Control

const QUEST_ACTION_BUTTON := preload("res://game/dialogue/quest_action_button.tscn")
const DIALOGUE_CHOICE_BUTTON := preload("res://game/dialogue/dialogue_choice_button.tscn")
@export var dialogue_entries: Array[LunexNpcDialogueDefinition] = []

signal quest_accept_requested(quest_id: String)

@onready var speaker: Label = %Speaker
@onready var body: RichTextLabel = %Body
@onready var choices: VBoxContainer = %Choices
@onready var close_button: Button = %Close
var _resource: DialogueResource
var _line: DialogueLine
var _chapter_state: Dictionary = {}
var _chapter_definitions: Array[LunexChapterQuestDefinition] = []
var _active_npc := ""

func _ready() -> void:
    close_button.pressed.connect(close_dialogue)

func set_quest_state(state: Dictionary, definitions: Array[LunexChapterQuestDefinition]) -> void:
    _chapter_state = state
    _chapter_definitions = definitions
    if visible:
        _refresh_quest_actions()

func _refresh_quest_actions() -> void:
    for child in %QuestActions.get_children():
        child.queue_free()
    for definition in _chapter_definitions:
        if definition.npc_id != _active_npc:
            continue
        if _chapter_state.has(definition.quest_id):
            continue
        if not definition.prerequisite_id.is_empty() and int(_chapter_state.get(definition.prerequisite_id, {}).get("state", 0)) != 2:
            continue
        var action := QUEST_ACTION_BUTTON.instantiate() as Button
        action.text = "Взять задание: " + definition.title
        %QuestActions.add_child(action)
        action.pressed.connect(func() -> void:
            quest_accept_requested.emit(definition.quest_id)
            action.disabled = true
        )

func open_dialogue(npc_id: String) -> void:
    _active_npc = npc_id
    _refresh_quest_actions()
    var source := LunexNpcDialogues.for_npc(npc_id)
    for definition in dialogue_entries:
        if definition != null and definition.npc_id == npc_id and definition.is_valid_definition():
            source = definition.dialogue_text
            break
    if source.is_empty():
        return
    _resource = get_node("/root/DialogueManager").create_resource_from_text(source)
    if _resource == null:
        return
    show()
    await _advance("start")

func _advance(cue: String) -> void:
    _line = await get_node("/root/DialogueManager").get_next_dialogue_line(_resource, cue)
    if _line == null:
        close_dialogue()
        return
    speaker.text = _line.character
    body.text = _line.text
    for node in choices.get_children():
        node.queue_free()
    if _line.responses.size() > 0:
        for response in _line.responses:
            if not response.is_allowed:
                continue
            var button := DIALOGUE_CHOICE_BUTTON.instantiate() as Button
            button.text = response.text
            choices.add_child(button)
            button.pressed.connect(func() -> void: _advance(response.next_id))
    else:
        var next := DIALOGUE_CHOICE_BUTTON.instantiate() as Button
        next.text = "Продолжить"
        choices.add_child(next)
        next.pressed.connect(func() -> void: _advance(_line.next_id))

func close_dialogue() -> void:
    hide()
    _resource = null
    _line = null
    _active_npc = ""
