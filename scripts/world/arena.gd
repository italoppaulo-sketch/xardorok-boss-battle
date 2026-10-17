extends Node2D
signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)
const Battle = preload("res://scripts/combat/battle.gd")
const Painter = preload("res://scripts/world/unit_painter.gd")
const Effects = preload("res://scripts/world/effects.gd")
const ORIGIN := Vector2(40, 130)
const TILE := 48.0
var battle: RefCounted
var selected := 0
var show_moves := false
var skill_id := "move"
var hovered := Vector2i(-1, -1)
var elapsed := 0.0
var positions := {}
var routes := {}
var scales := {}
var attacks := {}
var effects := Effects.new()


func _ready() -> void:
	add_child(effects)


func reset_visuals() -> void:
	positions.clear()
	routes.clear()
	scales.clear()
	attacks.clear()
	effects.active.clear()


func present(events: Array[Dictionary]) -> void:
	var delays := {}
	for event in events:
		var source: int = event.get("source", -1)
		if event.kind == "move":
			if not positions.has(source):
				positions[source] = center(event.from)
			if not routes.has(source):
				routes[source] = []
			routes[source].append_array(event.path)
			delays[source] = routes[source].size() * 0.1
			continue
		var from: Vector2 = (
			center(battle.units[source].cell)
			if battle.valid_unit(source)
			else center(event.get("cell", Vector2i.ZERO))
		)
		var target: int = event.get("target", -1)
		var to: Vector2 = (
			center(battle.units[target].cell)
			if battle.valid_unit(target)
			else center(event.get("cell", Vector2i.ZERO))
		)
		var visual := event.duplicate(true)
		visual.delay = float(visual.get("delay", 0.0)) + float(delays.get(source, 0.0))
		if event.kind == "cast":
			attacks[source] = {
				"start": elapsed + visual.delay, "end": elapsed + visual.delay + 0.55
			}
		effects.add_event(visual, from, to)


func _process(delta: float) -> void:
	elapsed += delta
	if battle == null:
		return
	var local := (get_global_mouse_position() - ORIGIN) / TILE
	var cell := Vector2i(floori(local.x), floori(local.y))
	if cell != hovered:
		hovered = cell
		cell_hovered.emit(cell)
	for i in battle.units.size():
		if not positions.has(i):
			positions[i] = center(battle.units[i].cell)
		if routes.has(i) and not routes[i].is_empty():
			var destination := center(routes[i][0])
			positions[i] = positions[i].move_toward(destination, delta * 480)
			if positions[i].distance_to(destination) < 0.1:
				routes[i].pop_front()
		else:
			positions[i] = positions[i].move_toward(center(battle.units[i].cell), delta * 480)
		scales[i] = lerpf(
			float(scales.get(i, 1.0)),
			1.6 if battle.has_status(i, "giant") else 1.0,
			minf(1, delta * 8)
		)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pointer: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		var local := (pointer - ORIGIN) / TILE
		var cell := Vector2i(floori(local.x), floori(local.y))
		if battle.inside(cell):
			cell_clicked.emit(cell)


func center(cell: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


func _draw() -> void:
	if battle == null:
		return
	_terrain()
	_indicators()
	for wall in Battle.WALLS:
		var point := center(wall)
		draw_rect(Rect2(point - Vector2(23, 12), Vector2(46, 40)), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(point - Vector2(19, 32), Vector2(38, 49)), Color("535364"))
		draw_rect(Rect2(point - Vector2(24, 38), Vector2(48, 12)), Color("85808a"))
		draw_line(point + Vector2(-14, -28), point + Vector2(-14, 10), Color("a49b9d"), 3)
		draw_line(point + Vector2(12, -28), point + Vector2(12, 10), Color("373c4a"), 5)
	for zone in battle.smoke:
		var point := center(zone.cell)
		for i in 14:
			var offset := Vector2.from_angle(i * 2.4) * float((i * 23) % 90)
			draw_circle(
				point + offset + Vector2(sin(elapsed + i) * 6, cos(elapsed + i) * 3),
				31,
				Color(0.45, 0.43, 0.5, 0.18)
			)
		draw_arc(point, zone.radius * TILE, 0, TAU, 48, Color(0.7, 0.66, 0.78, 0.35), 2)
	# Ordenar por altura no cenário é apenas visual; os índices estáveis regem a iniciativa.
	var order: Array[int] = []
	for i in battle.units.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int): return battle.units[a].cell.y < battle.units[b].cell.y)
	for i in order:
		_unit(i)
	if not battle.outcome.is_empty():
		draw_rect(
			Rect2(ORIGIN + Vector2(60, 155), Vector2(600, 110)), Color(0.04, 0.05, 0.08, 0.92)
		)
		draw_line(ORIGIN + Vector2(80, 165), ORIGIN + Vector2(640, 165), Color("ad9161"), 2)
		draw_string(
			ThemeDB.fallback_font,
			ORIGIN + Vector2(160, 215),
			battle.outcome,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			30,
			Color("ead79d")
		)


func _terrain() -> void:
	draw_rect(Rect2(ORIGIN - Vector2(7, 7), Vector2(734, 446)), Color("6b5c52"))
	draw_rect(Rect2(ORIGIN, Vector2(720, 432)), Color("303341"))
	# Grandes lajes irregulares: não correspondem à grade lógica de 48 pixels.
	for y in 4:
		for x in 7:
			var at := ORIGIN + Vector2(x * 105 + ((y % 2) * 16), y * 110)
			var width := minf(100, ORIGIN.x + 718 - at.x)
			if width > 0:
				draw_rect(
					Rect2(at + Vector2(3, 3), Vector2(width, 103)),
					Color("373b48") if (x + y) % 3 else Color("3c3e4b")
				)
	for i in 45:
		var point := ORIGIN + Vector2((i * 137 + 31) % 700, (i * 83 + 19) % 420)
		draw_line(point, point + Vector2(14, -2), Color("4a4851"), 1)
	draw_arc(center(Vector2i(11, 4)), 96, 0, TAU, 48, Color("66514c"), 2)
	draw_arc(center(Vector2i(11, 4)), 103, 0, TAU, 48, Color("494653"), 2)
	for cell in [Vector2i(0, 0), Vector2i(14, 0), Vector2i(0, 8), Vector2i(14, 8)]:
		var point := center(cell)
		draw_circle(point, 27, Color(1, 0.35, 0.1, 0.07))
		draw_rect(Rect2(point - Vector2(12, 3), Vector2(24, 14)), Color("57505b"))
		draw_colored_polygon(
			PackedVector2Array(
				[
					point + Vector2(-9, -1),
					point + Vector2(-3, -24 - sin(elapsed * 4) * 4),
					point + Vector2(3, -14),
					point + Vector2(9, -2)
				]
			),
			Color("ef9b56")
		)


func _indicators() -> void:
	for mark in battle.meteors:
		for y in Battle.SIZE.y:
			for x in Battle.SIZE.x:
				var cell := Vector2i(x, y)
				if battle.distance(cell, mark.cell) <= mark.radius:
					draw_circle(
						center(cell), 22, Color(1, 0.25, 0.1, 0.13 + sin(elapsed * 5) * 0.05)
					)
					draw_arc(center(cell), 21, 0, TAU, 24, Color("ff8a58"), 2)
	if not battle.outcome.is_empty() or battle.units[selected].hp <= 0:
		return
	if show_moves:
		for cell in battle.reachable(selected):
			draw_circle(center(cell), 3, Color(0.55, 0.83, 0.9, 0.6))
	else:
		var skill := Battle.Abilities.get_skill(skill_id)
		if skill.is_empty():
			return
		var color := Color(skill.color)
		for y in Battle.SIZE.y:
			for x in Battle.SIZE.x:
				var cell := Vector2i(x, y)
				if skill.target != "self" and battle.can_use(selected, skill_id, cell).is_empty():
					draw_arc(center(cell), 20, 0, TAU, 20, Color(color, 0.5), 1)
		if battle.inside(hovered) and battle.can_use(selected, skill_id, hovered).is_empty():
			if skill.get("radius", 0) > 0:
				for y in Battle.SIZE.y:
					for x in Battle.SIZE.x:
						var cell := Vector2i(x, y)
						if battle.distance(cell, hovered) <= skill.radius:
							draw_circle(center(cell), 21, Color(color, 0.18))
			elif skill_id == "chain":
				var previous := center(battle.units[selected].cell)
				for target in battle.chain_targets(battle.unit_at(hovered), 4, 3):
					var point := center(battle.units[target].cell)
					draw_line(previous, point, Color(color, 0.5), 2)
					previous = point
	if battle.inside(hovered):
		draw_arc(center(hovered), 23, 0, TAU, 24, Color("dec796"), 2)


func _unit(index: int) -> void:
	var unit: Dictionary = battle.units[index]
	var point: Vector2 = positions.get(index, center(unit.cell))
	if unit.hp <= 0:
		draw_line(point - Vector2(7, 7), point + Vector2(7, 7), Color("7b6e71"), 3)
		draw_line(point + Vector2(7, -7), point + Vector2(-7, 7), Color("7b6e71"), 3)
		return
	draw_set_transform(point, 0, Vector2(1, 0.35))
	draw_circle(Vector2(0, 35), 22, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if index == selected:
		draw_arc(point + Vector2(0, 13), 24, 0, TAU, 32, Color("e9d29d"), 2)
	if index == 5:
		draw_circle(point, 47, Color(1, 0.25, 0.05, 0.06 + sin(elapsed * 3) * 0.02))
		draw_arc(point, 46, 0, TAU, 32, Color(0.9, 0.4, 0.2, 0.22), 1)
	var attacking: bool = (
		attacks.has(index) and elapsed >= attacks[index].start and elapsed < attacks[index].end
	)
	var offset := (
		Vector2(sin((elapsed - attacks[index].start) * PI / 0.55) * 5, 0)
		if attacking
		else Vector2.ZERO
	)
	if battle.has_status(index, "illusion"):
		Painter.paint(self, unit, index, point + Vector2(-25, 8), elapsed, 0.82, false)
		draw_circle(point + Vector2(-25, 0), 21, Color(0.35, 0.65, 1, 0.18))
	Painter.paint(
		self, unit, index, point + offset, elapsed, float(scales.get(index, 1.0)), attacking
	)
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(point + Vector2(-22, 29), Vector2(44, 6)), Color("0e1420"))
	draw_rect(Rect2(point + Vector2(-21, 30), Vector2(42.0 * unit.hp / unit.max_hp, 4)), unit.color)
	draw_string(
		font,
		point + Vector2(-28, -46 * float(scales.get(index, 1.0))),
		unit.name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color("eee5d5")
	)
	var state_x := -20
	for id in unit.statuses:
		var definition: Dictionary = Battle.Statuses.DEFINITIONS[id]
		draw_circle(point + Vector2(state_x, 43), 6, Color(definition.color).darkened(0.5))
		draw_string(
			font,
			point + Vector2(state_x - 3, 47),
			definition.short,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			Color("f1eee7")
		)
		state_x += 11
	if battle.has_status(index, "burning"):
		for i in 3:
			var flame := point + Vector2(-13 + i * 12, 7 + sin(elapsed * 8 + i) * 4)
			draw_colored_polygon(
				PackedVector2Array(
					[flame + Vector2(-4, 7), flame + Vector2(0, -8), flame + Vector2(4, 7)]
				),
				Color(1, 0.45, 0.1, 0.7)
			)
