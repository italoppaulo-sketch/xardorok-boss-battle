extends Node2D
## Indicadores projetados; HUD permanece em CanvasLayer independente.
var arena: Node2D


func _draw() -> void:
	if arena == null or arena.battle == null:
		return
	var b: RefCounted = arena.battle
	var font := ThemeDB.fallback_font
	for i in arena.visual_units.size():
		var unit: Dictionary = arena.visual_units[i]
		if unit.hp <= 0 or not arena.visible_to_player(i):
			continue
		var foot: Vector2 = arena.screen_position(i)
		var head: Vector2 = arena.project_world(
			(
				arena.displayed_world(i)
				+ (
					arena.orbit.camera.global_basis.y
					* arena.actors[i].idle_height
					* 0.02
					* arena.actors[i].scale.x
				)
			)
		)
		var color := Color("e9cd86") if i == arena.selected else Color(unit.color, 0.5)
		_ground_ring(arena.displayed_world(i), 0.31, color, 2 if i == arena.selected else 1)
		draw_rect(Rect2(foot + Vector2(-20, 6), Vector2(40, 6)), Color("101623"))
		draw_rect(
			Rect2(foot + Vector2(-19, 7), Vector2(38.0 * unit.hp / unit.max_hp, 4)), unit.color
		)
		draw_string(
			font,
			head + Vector2(-25, -7),
			unit.name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color("f1e8d9")
		)
		var statuses: PackedStringArray = []
		for id in unit.statuses:
			statuses.append(str(b.Statuses.DEFINITIONS[id].short))
		if not statuses.is_empty():
			draw_string(
				font,
				foot + Vector2(-18, 25),
				" ".join(statuses),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				Color("ffcf8d")
			)
	for mark in arena.visual_meteors:
		for y in b.SIZE.y:
			for x in b.SIZE.x:
				var cell := Vector2i(x, y)
				if b.inside(cell) and b.distance(cell, mark.cell) <= mark.radius:
					_ground_ring(arena.world_cell(cell), 0.44, Color("ff8a58"), 2)
		draw_string(
			font,
			arena.project_cell(mark.cell) + Vector2(-35, -15),
			"IMPACTO IMINENTE",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			Color("ffd19c")
		)
	if b.meteor_window:
		if arena.skill_id == "meteor_evade" and not arena.timeline.playing:
			for cell in b.emergency_destinations(arena.selected):
				draw_circle(arena.project_cell(cell), 5, Color("a8e7da"))
		return
	if arena.timeline.playing or not b.outcome.is_empty() or arena.selected != b.active_index:
		return
	if arena.show_moves:
		for cell in b.preview_reachable(arena.selected):
			draw_circle(arena.project_cell(cell), 3, Color(0.55, 0.83, 0.9, 0.7))
	else:
		var skill: Dictionary = b.Abilities.get_skill(arena.skill_id)
		if not skill.is_empty() and skill.target != "self":
			for y in b.SIZE.y:
				for x in b.SIZE.x:
					var cell := Vector2i(x, y)
					if b.can_use(arena.selected, arena.skill_id, cell).is_empty():
						_ground_ring(
							arena.world_cell(cell), 0.38, Color(Color(skill.color), 0.45), 1
						)
			if b.inside(arena.hovered) and skill.get("radius", 0) > 0:
				for y in b.SIZE.y:
					for x in b.SIZE.x:
						var cell := Vector2i(x, y)
						if b.inside(cell) and b.distance(cell, arena.hovered) <= skill.radius:
							_ground_ring(arena.world_cell(cell), 0.44, Color(skill.color), 2)
	if b.inside(arena.hovered):
		_ground_ring(arena.world_cell(arena.hovered), 0.45, Color("dec796"), 2)


func _ground_ring(center: Vector3, radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for step in 33:
		var angle := step * TAU / 32
		points.append(
			arena.project_world(center + Vector3(sin(angle) * radius, 0.04, cos(angle) * radius))
		)
	draw_polyline(points, color, width, true)
