@tool
extends PanelContainer

signal close_requested
signal activation_requested
signal drag_started(screen_position: Vector2)

@export var title := "Untitled":
	set(value):
		title = value
		if is_node_ready():
			%Title.text = title
@export var window_icon: Texture2D:
	set(value):
		window_icon = value
		if is_node_ready():
			%Icon.texture = window_icon
@export var closable := false:
	set(value):
		closable = value
		if is_node_ready():
			%Close.visible = closable
@export var active := false:
	set(value):
		active = value
		theme_type_variation = &"Titlebar" if active else &"TitlebarInactive"

func _ready() -> void:
	%Title.text = title
	%Icon.texture = window_icon
	%Close.visible = closable
	theme_type_variation = &"Titlebar" if active else &"TitlebarInactive"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activation_requested.emit()
		drag_started.emit(event.global_position)
		accept_event()

func _on_close_pressed() -> void:
	close_requested.emit()
