extends Control

@export var portrait := false
var effects_enabled := true
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	if effects_enabled:
		queue_redraw()

func _draw() -> void:
	if portrait:
		_draw_cat()
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("090d19"))
	for x in range(0, int(size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.10, 0.30, 0.40, 0.11))
	for y in range(0, int(size.y), 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.10, 0.30, 0.40, 0.11))
	draw_circle(Vector2(size.x * 0.84, 90), 170, Color(0.6, 0.05, 0.45, 0.07))
	draw_circle(Vector2(90, size.y * 0.8), 220, Color(0.0, 0.8, 0.7, 0.04))
	if effects_enabled:
		var y := fmod(elapsed * 18.0, size.y)
		draw_rect(Rect2(0, y, size.x, 2), Color(0.2, 1.0, 0.9, 0.025))

func _draw_cat() -> void:
	var s := minf(size.x, size.y)
	var origin := (size - Vector2(s, s)) * 0.5
	draw_set_transform(origin, 0, Vector2(s / 160.0, s / 160.0))
	draw_rect(Rect2(0, 0, 160, 160), Color("141a30"))
	for y in range(0, 160, 8):
		draw_line(Vector2(0, y), Vector2(160, y), Color("24304a"))
	var outline := PackedVector2Array([Vector2(24, 112), Vector2(28, 26), Vector2(58, 49), Vector2(100, 49), Vector2(132, 26), Vector2(138, 112), Vector2(112, 139), Vector2(48, 139)])
	draw_colored_polygon(outline, Color("243c55"))
	draw_polyline(outline + PackedVector2Array([outline[0]]), Color("00ffcc"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(36, 39), Vector2(39, 67), Vector2(55, 56)]), Color("ff369a"))
	draw_colored_polygon(PackedVector2Array([Vector2(123, 39), Vector2(105, 56), Vector2(124, 66)]), Color("ff369a"))
	var blink := effects_enabled and fmod(elapsed, 6.0) > 5.82
	draw_rect(Rect2(42, 79, 28, 3 if blink else 13), Color("00ffcc"))
	draw_rect(Rect2(92, 79, 28, 3 if blink else 13), Color("00ffcc"))
	draw_line(Vector2(79, 100), Vector2(85, 100), Color("ff369a"), 5)
	draw_polyline(PackedVector2Array([Vector2(65, 112), Vector2(80, 117), Vector2(96, 110)]), Color("f4d67a"), 2)
	for y in [102, 110]:
		draw_line(Vector2(15, y - 5), Vector2(57, y), Color("9cb5cf"), 1)
		draw_line(Vector2(106, y), Vector2(148, y - 5), Color("9cb5cf"), 1)
	if effects_enabled:
		draw_rect(Rect2(0, fmod(elapsed * 25.0, 160), 160, 3), Color(1, 0.1, 0.6, 0.2))
