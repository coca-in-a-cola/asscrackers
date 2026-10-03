@tool
extends PanelContainer

@export var text := "Ready":
	set(value):
		text = value
		if is_node_ready():
			%Text.text = text

@onready var text_label: Label = %Text

func _ready() -> void:
	text_label.text = text
