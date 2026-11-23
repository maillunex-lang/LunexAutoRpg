class_name LunexDialogueWindow
extends Control

@onready var speaker: Label = %Speaker
@onready var body: RichTextLabel = %Body
@onready var choices: VBoxContainer = %Choices
@onready var close_button: Button = %Close
var _resource: DialogueResource
var _line: DialogueLine

func _ready() -> void:
    close_button.pressed.connect(close_dialogue)

func open_dialogue(npc_id: String) -> void:
    var source := LunexNpcDialogues.for_npc(npc_id)
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
            var button := Button.new()
            button.text = response.text
            choices.add_child(button)
            button.pressed.connect(func() -> void: _advance(response.next_id))
    else:
        var next := Button.new()
        next.text = "Продолжить"
        choices.add_child(next)
        next.pressed.connect(func() -> void: _advance(_line.next_id))

func close_dialogue() -> void:
    hide()
    _resource = null
    _line = null
