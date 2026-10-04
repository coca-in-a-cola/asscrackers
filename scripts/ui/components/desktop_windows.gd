extends Control
## Applications stay alive when closed. This manager owns geometry and focus,
## never the jobs or data displayed by the applications.

signal windows_changed
signal window_moved(application_name: StringName)
signal layout_ready

var active_application: StringName = &""
var _dragging: Control
var _drag_offset := Vector2.ZERO
var _initialized := false

func _ready() -> void:
	for window in get_children():
		window.closable = true
		window.active = false
		window.activation_requested.connect(focus_application.bind(StringName(window.name)))
		window.close_requested.connect(close_application.bind(StringName(window.name)))
		window.drag_started.connect(_start_drag.bind(window))
		# Native buttons/inputs consume mouse events. Focus still activates their
		# owning application before its action, including keyboard navigation.
		for control in window.find_children("*", "Control", true, false):
			control.focus_entered.connect(focus_application.bind(StringName(window.name)))
	resized.connect(_clamp_windows)
	get_window().focus_exited.connect(cancel_drag)
	call_deferred("_initialize_layout")

func _initialize_layout() -> void:
	var compact := size.x < 1250.0 or size.y < 780.0
	var placements: Dictionary
	if compact:
		placements = {
			&"Terminal": Rect2(112, 18, 550, 260),
			&"Dictionary": Rect2(112, 272, 550, 380),
			&"Operator": Rect2(size.x - 370, 24, 350, 172),
			&"Dossier": Rect2(size.x - 460, 204, 440, 410),
		}
	else:
		placements = {
			&"Terminal": Rect2(168, 88, 610, 304),
			&"Dictionary": Rect2(200, 408, 610, 380),
			&"Operator": Rect2(844, 44, 350, 172),
			&"Dossier": Rect2(830, 234, 590, 538),
		}
	# Hidden Containers do not complete their wrapped-text reflow. Lay windows
	# out invisibly, then restore their authored visibility before interaction.
	var opacity := modulate.a
	modulate.a = 0.0
	var visibility: Dictionary = {}
	for window in get_children():
		visibility[window] = window.visible
		window.show()
		var rect: Rect2 = placements[StringName(window.name)]
		window.size = rect.size
		window.position = rect.position
	# Wrapped labels first need a real width. Their temporary zero-width minimum
	# height must not become a permanently oversized free-floating window.
	for frame in 4:
		await get_tree().process_frame
	for window in get_children():
		var rect: Rect2 = placements[StringName(window.name)]
		window.size = rect.size.max(window.get_combined_minimum_size())
		window.visible = visibility[window]
	_initialized = true
	modulate.a = opacity
	_clamp_windows()
	focus_application(active_application)
	windows_changed.emit()
	layout_ready.emit()

func layout_is_ready() -> bool:
	return _initialized

func application(application_name: StringName) -> Control:
	if application_name.is_empty():
		return null
	return get_node_or_null(NodePath(application_name)) as Control

func open_application(application_name: StringName) -> void:
	var window := application(application_name)
	if window == null:
		return
	window.show()
	focus_application(application_name)

func close_application(application_name: StringName) -> void:
	var window := application(application_name)
	if window == null:
		return
	if _dragging == window:
		cancel_drag()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and window.is_ancestor_of(focused):
		focused.release_focus()
	window.hide()
	window.active = false
	if active_application == application_name:
		active_application = &""
		for index in range(get_child_count() - 1, -1, -1):
			var next := get_child(index) as Control
			if next.visible:
				focus_application(StringName(next.name))
				break
	windows_changed.emit()

func focus_application(application_name: StringName) -> void:
	if not _initialized:
		return
	var window := application(application_name)
	if window == null or not window.visible:
		return
	active_application = application_name
	for child in get_children():
		child.active = child == window
	move_child(window, get_child_count() - 1)
	windows_changed.emit()

func _start_drag(screen_position: Vector2, window: Control) -> void:
	focus_application(StringName(window.name))
	_dragging = window
	_drag_offset = screen_position - window.global_position

func cancel_drag() -> void:
	_dragging = null

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_dragging):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		cancel_drag()
	elif event is InputEventMouseMotion:
		_dragging.position = _bounded(event.position - global_position - _drag_offset, _dragging.size)
		window_moved.emit(StringName(_dragging.name))
		get_viewport().set_input_as_handled()

func _bounded(point: Vector2, window_size: Vector2) -> Vector2:
	return point.clamp(Vector2(8, 8), Vector2(maxf(8, size.x - window_size.x - 8), maxf(8, size.y - window_size.y - 8)))

func _clamp_windows() -> void:
	if not _initialized:
		return
	for window in get_children():
		window.position = _bounded(window.position, window.size)
		window_moved.emit(StringName(window.name))
