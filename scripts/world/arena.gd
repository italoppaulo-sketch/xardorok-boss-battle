extends Node2D
signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)
signal presentation_started
signal presentation_finished
const Battle = preload("res://scripts/combat/battle.gd")
const Effects = preload("res://scenes/effects/combat_effects.tscn")
const Actor = preload("res://scenes/characters/combat_sprite.tscn")
const Timeline = preload("res://scripts/visuals/timeline.gd")
const ArenaEnvironment = preload("res://scenes/environments/xardorok_arena.tscn")
const Overlay = preload("res://scripts/visuals/unit_overlay.gd")
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
var actors := {}
var effects = Effects.instantiate()
var timeline := Timeline.new()
var sorting := Node2D.new()
var environment = ArenaEnvironment.instantiate()
var overlay := Overlay.new()
var visual_units: Array[Dictionary] = []
var visual_smoke: Array[Dictionary] = []
var visual_meteors: Array[Dictionary] = []
var spirit: Node2D
var spirit_age := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sorting.y_sort_enabled = true
	add_child(environment)
	add_child(sorting)
	environment.setup(Battle.SIZE, Battle.WALLS, ORIGIN, TILE, sorting)
	add_child(effects)
	overlay.arena = self
	overlay.z_index = 40
	add_child(overlay)
	capture_state()
	_ensure_actors()


func capture_state() -> void:
	visual_units = battle.units.duplicate(true)
	visual_smoke = battle.smoke.duplicate(true)
	visual_meteors = battle.meteors.duplicate(true)


func _ensure_actors() -> void:
	for i in battle.units.size():
		if not positions.has(i):
			positions[i] = center(battle.units[i].cell)
		if visual_units.size() <= i:
			visual_units.append(battle.units[i].duplicate(true))
		if not actors.has(i):
			var actor = Actor.instantiate()
			actor.configure(i)
			actor.sprite.flip_h = battle.units[i].enemy
			sorting.add_child(actor)
			actors[i] = actor


func reset_visuals() -> void:
	timeline.begin()
	for actor in actors.values():
		actor.queue_free()
	actors.clear()
	positions.clear()
	routes.clear()
	scales.clear()
	effects.active.clear()
	if is_instance_valid(spirit):
		spirit.queue_free()
	spirit = null
	capture_state()
	_ensure_actors()


func present(events: Array[Dictionary]) -> void:
	if events.is_empty():
		return
	_ensure_actors()
	timeline.begin()
	var cursor := 0.0
	var impact := 0.12
	var skill := ""
	for original in events:
		var event := original.duplicate(true)
		var source: int = event.get("source", -1)
		match event.kind:
			"move":
				timeline.add(
					cursor, {"kind": "route", "source": source, "path": event.path.duplicate()}
				)
				cursor += event.path.size() * 0.1
				impact = cursor + 0.12
			"cast":
				skill = event.ability
				var data := Battle.Abilities.get_skill(skill)
				impact = cursor + (0.2 if data.get("target", "") == "self" else 0.55)
				if skill in ["double", "unarmed"]:
					impact = cursor + 0.34
				if skill == "fushigiri":
					impact = cursor + 0.45
				var animation := (
					"attack"
					if (
						skill
						in [
							"basic",
							"double",
							"unarmed",
							"root_arrow",
							"ice_arrow",
							"energy_arrow",
							"purple_fire",
							"red_laser"
						]
					)
					else "cast"
				)
				if skill in ["giant", "fushigiri", "flight", "illusion", "meteors", "summon"]:
					animation = "special"
				if skill == "heal":
					animation = "attack_alt"
				timeline.add(cursor, {"kind": "animation", "actor": source, "animation": animation})
				if skill in ["double", "unarmed"]:
					timeline.add(
						cursor + 0.4,
						{"kind": "animation", "actor": source, "animation": "attack_alt"}
					)
				timeline.add(cursor + 0.1, event)
				cursor += 0.9
			"meteor":
				impact = cursor + 0.3
				var centers: Array[Vector2] = []
				for direction in Battle.DIRECTIONS + [Vector2i.ZERO]:
					var cell: Vector2i = event.cell + direction
					if battle.inside(cell):
						centers.append(center(cell))
				event.area_centers = centers
				timeline.add(cursor, event)
				timeline.add(impact, {"kind": "remove_mark", "cell": event.cell})
				cursor += 0.7
				skill = "meteor"
			"damage", "heal", "recoil", "miss":
				var at := impact
				if skill in ["double", "unarmed"] and float(event.get("delay", 0.0)) > 0.0:
					at += 0.4
				event.delay = 0.0
				timeline.add(at, event)
			"link":
				timeline.add(maxf(0, impact - 0.1), event)
			"spawn":
				actors[event.target].visible = false
				timeline.add(impact, event)
			"status":
				timeline.add(impact, event)
			"expire":
				timeline.add(cursor, event)
			"spirit":
				timeline.add(cursor, event)
				impact = cursor + 0.8
				cursor += 2.8
			_:
				timeline.add(impact, event)
	timeline.finish_build(cursor + 0.3)
	presentation_started.emit()


func _apply_visual(event: Dictionary) -> void:
	var source: int = event.get("source", -1)
	var target: int = event.get("target", -1)
	match event.kind:
		"route":
			routes[source] = event.path.duplicate()
			return
		"animation":
			if actors.has(event.actor):
				actors[event.actor].animate(event.animation)
			return
		"remove_mark":
			for mark in visual_meteors.duplicate():
				if mark.cell == event.cell:
					visual_meteors.erase(mark)
			return
		"status":
			if target >= 0 and event.has("status_id"):
				visual_units[target].statuses[event.status_id] = event.turns
		"expire":
			if target >= 0 and event.has("status_id"):
				visual_units[target].statuses.erase(event.status_id)
			return
		"damage", "recoil", "heal":
			if target >= 0:
				var unit: Dictionary = visual_units[target]
				var sign_value := 1 if event.kind == "heal" else -1
				unit.hp = clampi(unit.hp + sign_value * event.amount, 0, unit.max_hp)
				if event.kind != "heal":
					actors[target].on_damage(unit.hp <= 0)
		"miss":
			if target >= 0:
				actors[target].animate("evade", 0.3)
		"spawn":
			if actors.has(target):
				actors[target].visible = true
		"spirit":
			if is_instance_valid(spirit):
				spirit.queue_free()
			var manifestation = Actor.instantiate()
			manifestation.configure(0, "dalamud")
			manifestation.sprite.material = ShaderMaterial.new()
			manifestation.sprite.material.shader = load("res://scripts/visuals/spirit.gdshader")
			manifestation.position = center(event.get("cell", Vector2i(5, 4))) + Vector2(0, -25)
			manifestation.scale = Vector2.ONE * 1.6
			manifestation.desired_scale = 1.6
			manifestation.z_index = 15
			sorting.add_child(manifestation)
			spirit = manifestation
			spirit_age = 0.0
			return
	var from: Vector2 = (
		center(battle.units[source].cell) + Vector2(8, -26)
		if battle.valid_unit(source)
		else center(event.get("cell", Vector2i.ZERO))
	)
	var to: Vector2 = (
		center(battle.units[target].cell) + Vector2(0, -23)
		if battle.valid_unit(target)
		else center(event.get("cell", Vector2i.ZERO))
	)
	if event.kind == "cast":
		to += Vector2(0, -23)
	if (
		event.kind == "cast"
		and actors.has(source)
		and event.get("cell") != battle.units[source].cell
	):
		actors[source].sprite.flip_h = to.x < from.x
	effects.add_event(event, from, to)


func _process(delta: float) -> void:
	elapsed += delta
	if battle == null:
		return
	var was_playing := timeline.playing
	for event in timeline.advance(delta):
		_apply_visual(event)
	if was_playing and not timeline.playing:
		capture_state()
		presentation_finished.emit()
	_ensure_actors()
	var local := (get_global_mouse_position() - ORIGIN) / TILE
	var cell := Vector2i(floori(local.x), floori(local.y))
	if cell != hovered:
		hovered = cell
		cell_hovered.emit(cell)
	for i in battle.units.size():
		var moving: bool = routes.has(i) and not routes[i].is_empty()
		if moving:
			var destination := center(routes[i][0])
			actors[i].sprite.flip_h = (
				destination.x < positions[i].x
				if absf(destination.x - positions[i].x) > 0.1
				else actors[i].sprite.flip_h
			)
			positions[i] = positions[i].move_toward(destination, delta * 480)
			if positions[i].distance_to(destination) < 0.1:
				routes[i].pop_front()
		elif not timeline.playing:
			positions[i] = positions[i].move_toward(center(battle.units[i].cell), delta * 480)
		actors[i].position = positions[i] + Vector2(0, 14)
		actors[i].sync(visual_units[i], moving)
		scales[i] = actors[i].scale.x
	if is_instance_valid(spirit):
		spirit_age += delta
		var wing_pose := "hover" if spirit_age >= 0.6 and spirit_age < 2.1 else "idle"
		if spirit.sprite.animation != wing_pose:
			spirit.sprite.play(wing_pose)
		spirit.modulate.a = minf(1, spirit_age * 2) * clampf((2.8 - spirit_age) * 2, 0, 1)
		if spirit_age >= 2.8:
			spirit.queue_free()
			spirit = null
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
	_indicators()
	for zone in visual_smoke:
		var texture: Texture2D = load("res://assets/effects/smoke/atlas.png")
		var frame := int(elapsed * 3) % 4
		var size2d: Vector2 = Vector2.ONE * zone.radius * TILE * 2
		draw_texture_rect_region(
			texture,
			Rect2(center(zone.cell) - size2d * 0.5, size2d),
			Rect2(frame * 96, 0, 96, 96),
			Color(0.8, 0.85, 0.95, 0.7)
		)
	if visual_units.size() > selected and visual_units[selected].hp > 0:
		draw_arc(
			positions.get(selected, center(battle.units[selected].cell)) + Vector2(0, 13),
			24,
			0,
			TAU,
			32,
			Color("ead7a0"),
			2
		)
	if visual_units.size() > 5 and visual_units[5].hp > 0:
		var boss: Vector2 = positions.get(5, center(battle.units[5].cell))
		draw_circle(boss, 47, Color(1, 0.28, 0.05, 0.07 + sin(elapsed * 3) * 0.02))
		draw_arc(boss, 46, 0, TAU, 32, Color(1, 0.4, 0.1, 0.3), 1)


func _indicators() -> void:
	for mark in visual_meteors:
		for y in Battle.SIZE.y:
			for x in Battle.SIZE.x:
				var cell := Vector2i(x, y)
				if battle.distance(cell, mark.cell) <= mark.radius:
					draw_circle(
						center(cell), 22, Color(1, 0.25, 0.1, 0.13 + sin(elapsed * 5) * 0.05)
					)
					draw_arc(center(cell), 21, 0, TAU, 24, Color("ff8a58"), 2)
	if timeline.playing or not battle.outcome.is_empty() or battle.units[selected].hp <= 0:
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


func paint_overlays(canvas: Node2D) -> void:
	var font := ThemeDB.fallback_font
	for i in visual_units.size():
		var unit: Dictionary = visual_units[i]
		if unit.hp <= 0 or not actors.has(i) or not actors[i].visible:
			continue
		var point: Vector2 = positions.get(i, center(battle.units[i].cell))
		canvas.draw_rect(Rect2(point + Vector2(-23, 27), Vector2(46, 7)), Color("101623"))
		canvas.draw_rect(
			Rect2(point + Vector2(-22, 28), Vector2(44.0 * unit.hp / unit.max_hp, 5)), unit.color
		)
		var height: float = actors[i].idle_height * actors[i].scale.x
		canvas.draw_string(
			font,
			point + Vector2(-28, -height - 1),
			unit.name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			13,
			Color("f1e8d9")
		)
		var at_x := -17
		for id in unit.statuses:
			if at_x > 27:
				break
			var definition: Dictionary = Battle.Statuses.DEFINITIONS[id]
			canvas.draw_circle(point + Vector2(at_x, 41), 5, Color(definition.color).darkened(0.45))
			canvas.draw_string(
				font,
				point + Vector2(at_x - 3, 45),
				definition.short,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				Color.WHITE
			)
			at_x += 11
	if not battle.outcome.is_empty() and not timeline.playing:
		canvas.draw_rect(
			Rect2(ORIGIN + Vector2(60, 155), Vector2(600, 110)), Color(0.04, 0.05, 0.08, 0.94)
		)
		canvas.draw_line(ORIGIN + Vector2(80, 165), ORIGIN + Vector2(640, 165), Color("ad9161"), 2)
		canvas.draw_string(
			font,
			ORIGIN + Vector2(160, 215),
			battle.outcome,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			30,
			Color("ead79d")
		)
