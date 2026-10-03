extends Control

signal node_selected(id: String)

const NodeScene = preload("res://scenes/ui/atoms/button.tscn")
const SourceIcon = preload("res://assets/ui/windows95/icons/icons--icon-small-notepad--2-750.png")
var nodes: Dictionary = {}
var _snapshot: Array = []
var _root: PanelContainer
var _root_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root = PanelContainer.new()
	_root.position = Vector2(28, 155)
	_root.size = Vector2(160, 70)
	_root.theme_type_variation = &"Inset"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root_label = Label.new()
	_root_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_label.text = "TARGET"
	_root.add_child(_root_label)

func apply_target(target: String) -> void:
	_root_label.text = target + "\nKNOWN IDENTITY"

func apply_snapshot(snapshot: Array) -> void:
	_snapshot = snapshot.duplicate(true)
	var keep: Dictionary = {}
	var extent := Vector2(440, 360)
	for fact in _snapshot:
		keep[fact.id] = true
		if not nodes.has(fact.id):
			var button := NodeScene.instantiate() as Button
			button.custom_minimum_size = Vector2(160, 64)
			button.size = Vector2(160, 64)
			button.icon = SourceIcon
			button.add_theme_font_size_override("font_size", 12)
			button.pressed.connect(func(): node_selected.emit(fact.id))
			add_child(button)
			nodes[fact.id] = button
		var node: Button = nodes[fact.id]
		node.position = Vector2(fact.position[0], fact.position[1])
		extent = extent.max(node.position + node.size + Vector2(24, 24))
		node.text = fact.label + ("\nRETRIEVED" if fact.revealed else "\n+%d EXP" % fact.cost)
		node.tooltip_text = fact.source + (" / reading is free" if fact.revealed else " / query this source")
	for id in nodes.keys():
		if not keep.has(id):
			var old: Control = nodes[id]
			remove_child(old)
			old.queue_free()
			nodes.erase(id)
	custom_minimum_size = extent
	queue_redraw()

func select_node(id: String) -> void:
	for key in nodes:
		nodes[key].modulate = Color(1, 0.92, 1) if key == id else Color.WHITE

func node_rect(id: String) -> Rect2:
	return nodes[id].get_global_rect() if nodes.has(id) else Rect2()

func _draw() -> void:
	if _root == null:
		return
	var ink := Color(0.38, 0.53, 0.57)
	for fact in _snapshot:
		var target: Control = nodes[fact.id]
		var parents: Array = fact.requires if not fact.requires.is_empty() else [""]
		for id in parents:
			var parent: Control = _root if id == "" else nodes.get(id)
			if parent == null:
				continue
			var start := parent.position + Vector2(parent.size.x, parent.size.y * 0.5)
			var end := target.position + Vector2(0, target.size.y * 0.5)
			draw_line(start, end, ink, 1.5, true)
			var direction := (end - start).normalized()
			draw_line(end, end - direction.rotated(0.45) * 8, ink, 1.5, true)
			draw_line(end, end - direction.rotated(-0.45) * 8, ink, 1.5, true)
