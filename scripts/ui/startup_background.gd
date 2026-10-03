@tool
extends Control

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var top := get_theme_color(&"background_top", &"Palette")
	var bottom := get_theme_color(&"background_bottom", &"Palette")
	var cyan := get_theme_color(&"cyan", &"Palette")
	var rose := get_theme_color(&"rose", &"Palette")
	for band in 64:
		var y := size.y * float(band) / 64.0
		draw_rect(Rect2(0, y, size.x, ceilf(size.y / 64.0) + 1.0), top.lerp(bottom, float(band) / 63.0))
	# The old terminal UI's geometry, drawn as wallpaper rather than PNG chrome.
	var grid := Color(cyan, 0.045)
	for x in range(0, int(size.x) + 1, 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid)
	for y in range(0, int(size.y) + 1, 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid)
	for y in range(0, int(size.y), 4):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.055))
	# Sparse, asymmetric registration marks keep the center quiet for credits.
	for point in [Vector2(20, 20), Vector2(size.x - 20, 20), Vector2(20, size.y - 20), size - Vector2(20, 20)]:
		var direction := Vector2(1 if point.x < size.x * 0.5 else -1, 1 if point.y < size.y * 0.5 else -1)
		draw_line(point, point + Vector2(28 * direction.x, 0), Color(cyan, 0.5), 2)
		draw_line(point, point + Vector2(0, 28 * direction.y), Color(cyan, 0.5), 2)
	for i in 16:
		var height := 10.0 if i % 4 == 0 else 4.0
		var x := size.x - 220 + i * 10
		draw_line(Vector2(x, size.y - 28), Vector2(x, size.y - 28 - height), Color(rose, 0.5), 2)
	draw_line(Vector2(20, size.y * 0.5 - 60), Vector2(20, size.y * 0.5 + 60), Color(rose, 0.7), 2)
