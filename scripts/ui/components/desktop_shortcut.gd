@tool
extends Button

signal application_requested(application_name: StringName)

@export var application_name: StringName
@export var caption := "Application":
	set(value):
		caption = value
		if is_node_ready():
			%Caption.text = caption
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if is_node_ready():
			%ShortcutIcon.texture = icon_texture

func _ready() -> void:
	%Caption.text = caption
	%ShortcutIcon.texture = icon_texture
	if not Engine.is_editor_hint():
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	application_requested.emit(application_name)
