@tool
extends "res://scripts/ui/components/window.gd"

signal primary_requested
signal secondary_requested

@onready var heading: Label = %Heading
@onready var body: RichTextLabel = %Body

func focus_primary() -> void:
	%Primary.grab_focus()

func _on_primary() -> void:
	primary_requested.emit()
func _on_secondary() -> void:
	secondary_requested.emit()
