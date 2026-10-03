@tool
extends Control

# The grid is wallpaper, not an effect: it stays visible with FX disabled.
var effects_enabled := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var top := get_theme_color(&"desktop_top", &"Palette")
	var bottom := get_theme_color(&"desktop_bottom", &"Palette")
	var step := 48.0
	for band in 64:
		var y := size.y * float(band) / 64.0
		draw_rect(Rect2(0, y, size.x, ceilf(size.y / 64.0) + 1.0), top.lerp(bottom, float(band) / 63.0))
	var grid := get_theme_color(&"desktop_grid", &"Palette")
	for x in range(0, int(size.x) + 1, int(step)):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1.0)
	for y in range(0, int(size.y) + 1, int(step)):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1.0)
	# Quiet desktop identity, kept clear of the applications and shortcuts.
	if size.x >= 1250.0 and size.y >= 848.0:
		var font := get_theme_font(&"font", &"Label")
		var ink := get_theme_color(&"desktop_ink", &"Palette")
		draw_string(font, Vector2(168, 48), "ASS / CRACKERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
		draw_string(font, Vector2(168, 68), "PERSONAL COMPUTE / 2091", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
