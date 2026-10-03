@tool
extends PanelContainer

signal remove_requested(fragment: String)

@export_range(1, 6) var slot_number := 1:
	set(value):
		slot_number = value
		if is_node_ready():
			%Status.text = "%02d / %s" % [slot_number, _status]
var fragment := ""
var _status := "EMPTY SLOT"

@onready var word_label: Label = %Word
@onready var remove_button: Button = %Remove

func _ready() -> void:
	apply("", "EMPTY SLOT", false)

func apply(word: String, status: String, can_edit: bool) -> void:
	fragment = word
	_status = status
	%Status.text = "%02d / %s" % [slot_number, status]
	word_label.text = word if not word.is_empty() else ("! ? # @" if status == "RULE SLOT" else "—")
	word_label.tooltip_text = word
	remove_button.visible = not word.is_empty()
	remove_button.disabled = not can_edit
	remove_button.tooltip_text = "Remove " + word

func _on_remove_pressed() -> void:
	remove_requested.emit(fragment)
