extends Node2D
signal cell_clicked(cell: Vector2i)
const Battle = preload("res://scripts/combat/battle.gd")
const ORIGIN := Vector2(40, 130)
const TILE := 48.0
var battle: RefCounted
var selected := 0
var show_moves := false
var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := (get_global_mouse_position() - ORIGIN) / TILE
		var cell := Vector2i(floori(local.x), floori(local.y))
		if battle.inside(cell):
			cell_clicked.emit(cell)


func center(cell: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


func _draw() -> void:
	if battle == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(ORIGIN - Vector2(6, 6), Vector2(732, 444)), Color("4d4143"))
	draw_rect(Rect2(ORIGIN, Vector2(720, 432)), Color("282832"))
	# Pedras decorativas, sem desenhar a grade tática.
	for i in 85:
		var point := ORIGIN + Vector2((i * 137 + 31) % 710, (i * 83 + 19) % 422)
		draw_line(point, point + Vector2(12, -2), Color("353440"), 2)
	if show_moves and battle.outcome.is_empty() and battle.units[selected].hp > 0:
		for cell in battle.reachable(selected):
			draw_circle(center(cell), 4, Color("78dce8"))
	for wall in Battle.WALLS:
		var position2d := center(wall)
		draw_rect(Rect2(position2d - Vector2(20, 22), Vector2(40, 44)), Color("4b4c5b"))
		draw_rect(Rect2(position2d - Vector2(17, 26), Vector2(34, 12)), Color("777587"))
	for i in battle.units.size():
		var unit: Dictionary = battle.units[i]
		var point := center(unit.cell)
		if unit.hp <= 0:
			draw_line(point - Vector2(8, 8), point + Vector2(8, 8), Color("777587"), 3)
			draw_line(point + Vector2(8, -8), point + Vector2(-8, 8), Color("777587"), 3)
			continue
		draw_set_transform(point, 0, Vector2(1, 0.4))
		draw_circle(Vector2(0, 20), 19, Color(0, 0, 0, 0.4))
		draw_set_transform(Vector2.ZERO)
		if i == selected:
			draw_arc(point + Vector2(0, 8), 23, 0, TAU, 32, Color("ecd798"), 2)
		var bob := sin(elapsed * 2 + i) * 1.5
		var body := point + Vector2(0, bob)
		if unit.enemy:
			draw_circle(body, 27, Color(1, 0.3, 0.05, 0.12 + 0.04 * sin(elapsed * 3)))
			draw_rect(Rect2(body - Vector2(16, 10), Vector2(32, 30)), Color("1c171d"))
			draw_line(body + Vector2(-9, -2), body + Vector2(9, 14), unit.color, 3)
			draw_circle(body - Vector2(0, 15), 10, Color("d9bdab"))
			draw_colored_polygon(
				PackedVector2Array(
					[body + Vector2(-9, -11), body + Vector2(9, -11), body + Vector2(0, 9)]
				),
				Color("eeeeeb")
			)
			draw_rect(Rect2(body - Vector2(11, 29), Vector2(22, 7)), Color("d6ae55"))
		else:
			draw_rect(Rect2(body - Vector2(10, 4), Vector2(20, 23)), unit.color.darkened(0.3))
			draw_circle(body - Vector2(0, 12), 8, unit.color)
			if i == 0:
				draw_line(body + Vector2(14, 10), body + Vector2(14, -15), Color("b4c1ca"), 3)
				draw_rect(Rect2(body + Vector2(8, -18), Vector2(15, 9)), Color("78dce8"))
			elif i == 3:
				draw_arc(body + Vector2(9, 0), 14, -1.2, 1.2, 12, Color("d6ae55"), 2)
			elif i == 4:
				draw_colored_polygon(
					PackedVector2Array(
						[
							body + Vector2(-8, -16),
							body + Vector2(-5, -27),
							body + Vector2(1, -16),
							body + Vector2(11, -10),
							body + Vector2(-8, -5)
						]
					),
					unit.color
				)
			draw_string(
				font,
				point + Vector2(-5, 5),
				str(i + 1),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				13,
				Color.WHITE
			)
		draw_rect(Rect2(point + Vector2(-20, 27), Vector2(40, 5)), Color("101015"))
		draw_rect(
			Rect2(point + Vector2(-20, 27), Vector2(40.0 * unit.hp / unit.max_hp, 5)), unit.color
		)
		draw_string(
			font,
			point + Vector2(-32, -36),
			unit.name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			13,
			Color("e5dfd2")
		)
