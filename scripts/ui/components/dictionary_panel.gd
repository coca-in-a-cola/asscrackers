@tool
extends "res://scripts/ui/components/window.gd"

signal fragment_submitted(value: String)
signal remove_requested(value: String)
signal special_requested(enabled: bool)

@onready var input: LineEdit = %Input
@onready var special_toggle: CheckBox = %Special
@onready var slots_label: Label = %Slots
@onready var chip_grid: GridContainer = %Grid
@onready var feedback: Label = %Feedback
@onready var add_button: Button = %Add

func _ready() -> void:
	super._ready()
	for slot in chip_grid.get_children():
		if not slot.remove_requested.is_connected(_on_remove_requested):
			slot.remove_requested.connect(_on_remove_requested)

func _on_remove_requested(value: String) -> void:
	remove_requested.emit(value)

func _on_input_submitted(value: String) -> void:
	fragment_submitted.emit(value)

func _on_add_pressed() -> void:
	fragment_submitted.emit(input.text)

func _on_special_toggled(enabled: bool) -> void:
	special_requested.emit(enabled)
