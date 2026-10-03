@tool
extends Container
## Fixed application layout. This host owns placement and activation; applications
## keep their own content and can later request close/minimize/drag through signals.

var active_application: StringName = &"Dictionary"

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_sort()
		return
	for application in get_children():
		if application.has_signal("activation_requested"):
			application.activation_requested.connect(focus_application.bind(StringName(application.name)))
	focus_application(active_application)

func focus_application(application_name: StringName) -> void:
	var application := get_node_or_null(NodePath(application_name)) as Control
	if application == null:
		return
	active_application = application_name
	for child in get_children():
		child.active = child == application
	move_child(application, get_child_count() - 1)
	queue_sort()

func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var compact := size.x < 1250.0 or size.y < 780.0
	var placements: Dictionary
	if compact:
		var left := 112.0
		var gap := 18.0
		var right_width := clampf(size.x * 0.34, 330.0, 390.0)
		var right_x := size.x - right_width - 20.0
		var workspace_width := right_x - gap - left
		var dictionary_height := 350.0
		var dictionary_y := size.y - dictionary_height - 18.0
		placements = {
			&"Terminal": Rect2(left, 28, workspace_width, dictionary_y - 42),
			&"Dictionary": Rect2(left, dictionary_y, workspace_width, dictionary_height),
			&"Operator": Rect2(right_x, 28, right_width, 156),
			&"Dossier": Rect2(right_x, 202, right_width, size.y - 220),
		}
	else:
		var offset := Vector2(maxf(0, (size.x - 1440.0) * 0.5), maxf(0, (size.y - 832.0) * 0.5))
		placements = {
			&"Terminal": Rect2(Vector2(168, 100) + offset, Vector2(600, 300)),
			&"Dictionary": Rect2(Vector2(200, 418) + offset, Vector2(600, 366)),
			&"Operator": Rect2(Vector2(844, 52) + offset, Vector2(350, 156)),
			&"Dossier": Rect2(Vector2(832, 238) + offset, Vector2(430, 528)),
		}
	for application in get_children():
		if application is Control and placements.has(StringName(application.name)):
			fit_child_in_rect(application, placements[StringName(application.name)])
