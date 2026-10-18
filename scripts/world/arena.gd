# gdlint: disable=max-returns
extends Node2D
signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)
signal unit_candidates_clicked(indices: Array[int], screen_position: Vector2)
signal presentation_started
signal presentation_finished
signal display_state_changed
const Battle = preload("res://scripts/combat/battle.gd")
const Effects = preload("res://scenes/effects/combat_effects.tscn")
const Actor = preload("res://scenes/characters/combat_sprite.tscn")
const Timeline = preload("res://scripts/visuals/timeline.gd")
const ArenaEnvironment = preload("res://scenes/environments/xardorok_arena.tscn")
const Overlay = preload("res://scripts/visuals/unit_overlay.gd")
const ORIGIN := Vector2(225, 104)
const TILE := 50.0
const MINION_DEATH_SECONDS := 0.65
var battle: RefCounted
var selected := 0
var target_highlight := -1
var retired_minions := {}
var minion_deaths := {}
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
var visual_fire: Array[Dictionary] = []
var movement_speed := 480.0
var cinematic_victory := false
var fire_fields: Node2D
var spirit: Node2D
var spirit_age := 0.0
var pending_spawns := {}
var fog := preload("res://scripts/visuals/smoke_cloud.gd").new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sorting.y_sort_enabled = true
	add_child(environment)
	add_child(sorting)
	environment.setup(Battle.SIZE, Battle.WALLS, ORIGIN, TILE, sorting)
	add_child(effects)
	fire_fields = load("res://scripts/visuals/fire_fields.gd").new()
	fire_fields.configure(self)
	add_child(fire_fields)
	fog.arena = self
	add_child(fog)
	overlay.arena = self
	overlay.z_index = 40
	add_child(overlay)
	capture_state()
	_ensure_actors()


func capture_state() -> void:
	visual_units = battle.units.duplicate(true)
	visual_smoke = battle.smoke.duplicate(true)
	visual_meteors = battle.meteors.duplicate(true)
	visual_fire.clear()
	if battle.get("fire_zones") != null:
		visual_fire.assign(battle.get("fire_zones").duplicate(true))
	if visual_units.size() > 5:
		visual_units[5].boss_phase = battle.boss_phase


func _ensure_actors() -> void:
	for i in battle.units.size():
		if retired_minions.has(i):
			continue
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
	pending_spawns.clear()
	retired_minions.clear()
	minion_deaths.clear()
	target_highlight = -1
	fog.reset()
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
	var chain_link_index := 0
	for original in events:
		var event := original.duplicate(true)
		var source: int = event.get("source", -1)
		match event.kind:
			"move":
				timeline.add(
					cursor, {"kind": "route", "source": source, "path": event.path.duplicate()}
				)
				cursor += event.path.size() * TILE / movement_speed
				impact = cursor + 0.12
			"cast":
				skill = event.ability
				chain_link_index = 0
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
				if (
					skill
					in [
						"giant",
						"fushigiri",
						"flight",
						"illusion",
						"meteors",
						"summon",
						"fire_shield",
						"fire_aura"
					]
				):
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
			"guard":
				timeline.add(cursor, event)
				cursor += 0.35
				impact = cursor
			"meteor":
				impact = cursor + 0.3
				var centers: Array[Vector2] = []
				for direction in (
					Battle.DIRECTIONS + [Vector2i.ZERO]
					if event.get("radius", 1) > 0
					else [Vector2i.ZERO]
				):
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
				if skill == "chain":
					at += maxi(0, chain_link_index - 1) * 0.12
				event.delay = 0.0
				timeline.add(at, event)
			"link":
				timeline.add(maxf(0, impact - 0.1) + chain_link_index * 0.12, event)
				chain_link_index += 1
			"spawn":
				if actors.has(event.target):
					actors[event.target].visible = false
				pending_spawns[event.target] = true
				timeline.add(impact, event)
			"world", "status":
				timeline.add(impact, event)
			"phase", "reaction":
				timeline.add(cursor, event)
				cursor += 0.35 if event.kind == "reaction" else 0.8
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
		"world":
			visual_smoke.assign(event.smoke_zones.duplicate(true))
			visual_meteors.assign(event.marks.duplicate(true))
			visual_fire.assign(event.get("fire_zones", visual_fire).duplicate(true))
			display_state_changed.emit()
			return
		"guard":
			if actors.has(target):
				actors[target].animate("evade", 0.55)
		"phase":
			visual_units[5].boss_phase = 2
			actors[5].animate("special", 0.8)
		"reaction":
			actors[5].animate("cast", 0.35)
			visual_meteors = battle.meteors.duplicate(true)
		"route":
			if actors.has(source):
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
				if event.kind != "heal" and actors.has(target):
					actors[target].on_damage(unit.hp <= 0)
					if target >= 6 and unit.hp <= 0 and not minion_deaths.has(target):
						minion_deaths[target] = elapsed
		"link":
			if actors.has(target) and actors[target].has_method("electric_pulse"):
				actors[target].electric_pulse()
		"miss":
			if actors.has(target):
				actors[target].animate("evade", 0.3)
		"spawn":
			pending_spawns.erase(target)
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
	display_state_changed.emit()
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
	if target >= 0 and not visible_to_player(target):
		return
	if (
		event.kind in ["cast", "link", "phase", "reaction"]
		and source >= 0
		and not visible_to_player(source)
	):
		return
	effects.add_event(event, from, to)


func visible_to_player(index: int) -> bool:
	if (
		index < 0
		or index >= visual_units.size()
		or pending_spawns.has(index)
		or retired_minions.has(index)
	):
		return false
	var observer: int = battle.observer_index()
	if observer >= visual_units.size():
		return false
	return (
		observer == index
		or Battle.Perception.presentation_line(
			displayed_cell(observer), displayed_cell(index), visual_smoke
		)
	)


func _process(delta: float) -> void:
	elapsed += delta
	if battle == null:
		return
	var was_playing := timeline.playing
	for event in timeline.advance(delta):
		_apply_visual(event)
	_ensure_actors()
	var cell := pointer_cell(to_local(get_global_mouse_position()))
	if cell != hovered:
		hovered = cell
		cell_hovered.emit(cell)
	var routes_pending := false
	for i in battle.units.size():
		if not actors.has(i):
			continue
		if i >= 6 and visual_units[i].hp <= 0:
			if not minion_deaths.has(i):
				minion_deaths[i] = elapsed
			var death_age: float = elapsed - minion_deaths[i]
			actors[i].modulate.a = clampf((MINION_DEATH_SECONDS - death_age) / 0.3, 0, 1)
			if death_age >= MINION_DEATH_SECONDS:
				_retire_minion(i)
				continue
		var remaining := delta * movement_speed
		while routes.has(i) and not routes[i].is_empty() and remaining > 0:
			var destination := center(routes[i][0])
			var distance_left: float = positions[i].distance_to(destination)
			if absf(destination.x - positions[i].x) > 0.1:
				actors[i].sprite.flip_h = destination.x < positions[i].x
			positions[i] = positions[i].move_toward(destination, remaining)
			remaining -= distance_left
			if positions[i].distance_to(destination) < 0.1:
				visual_units[i].cell = routes[i].pop_front()
			else:
				break
		var moving: bool = routes.has(i) and not routes[i].is_empty()
		routes_pending = routes_pending or moving
		if not moving and not timeline.playing:
			positions[i] = positions[i].move_toward(
				center(battle.units[i].cell), delta * movement_speed
			)
		actors[i].position = positions[i] + Vector2(0, 14)
		actors[i].sync(visual_units[i], moving)
		scales[i] = actors[i].scale.x
	# Uma queda de FPS não encerra a apresentação antes de completar o caminho.
	if was_playing and not timeline.playing and routes_pending:
		timeline.playing = true
	if was_playing and not timeline.playing:
		capture_state()
		presentation_finished.emit()
	# Todos os observadores já estão na posição desenhada deste mesmo frame.
	for i in actors:
		actors[i].visible = visible_to_player(i)
	_stable_depth_order()
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
		var candidates := pick_candidates(pointer)
		if candidates.size() > 1:
			unit_candidates_clicked.emit(candidates, event.position)
			return
		var cell := pointer_cell(pointer)
		if battle.inside(cell):
			cell_clicked.emit(cell)


func pick_candidates(pointer: Vector2) -> Array[int]:
	var result: Array[int] = []
	var global_pointer := to_global(pointer)
	for index in actors:
		if (
			battle.units[index].hp <= 0
			or visual_units[index].hp <= 0
			or not visible_to_player(index)
		):
			continue
		# A small ellipse at the actual feet complements alpha-aware sprite picking.
		# It does not expand the whole cell or reveal concealed combatants.
		var delta: Vector2 = pointer - actors[index].position
		var feet := Vector2(delta.x / 18.0, delta.y / 9.0).length_squared() <= 1.0
		if feet or actors[index].contains_point(global_pointer):
			result.append(index)
	result.sort_custom(func(a: int, b: int): return _in_front(a, b))
	return result


func pointer_cell(pointer: Vector2) -> Vector2i:
	var candidates := pick_candidates(pointer)
	if not candidates.is_empty():
		return battle.units[candidates[0]].cell
	var local := (pointer - ORIGIN) / TILE
	return Vector2i(floori(local.x), floori(local.y))


func _in_front(a: int, b: int) -> bool:
	if not is_equal_approx(actors[a].position.y, actors[b].position.y):
		return actors[a].position.y > actors[b].position.y
	if not is_equal_approx(actors[a].position.x, actors[b].position.x):
		return actors[a].position.x > actors[b].position.x
	return a > b


func _stable_depth_order() -> void:
	# Y-sort controls depth; stable sibling order resolves equal foot Y without
	# assigning a z-index that would force a whole character above another row.
	var order: Array = actors.keys()
	order.sort_custom(func(a: int, b: int): return _in_front(b, a))
	for index in order:
		sorting.move_child(actors[index], sorting.get_child_count() - 1)


func _retire_minion(index: int) -> void:
	retired_minions[index] = true
	if actors.has(index):
		actors[index].queue_free()
		actors.erase(index)
	positions.erase(index)
	routes.erase(index)
	scales.erase(index)
	pending_spawns.erase(index)
	minion_deaths.erase(index)
	if target_highlight == index:
		target_highlight = -1


func displayed_cell(index: int) -> Vector2:
	if positions.has(index):
		return (positions[index] - ORIGIN) / TILE - Vector2(0.5, 0.5)
	return Vector2(visual_units[index].cell)


func center(cell: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


func _draw() -> void:
	if battle == null:
		return
	_indicators()
	if (
		actors.has(target_highlight)
		and battle.units[target_highlight].hp > 0
		and visible_to_player(target_highlight)
	):
		draw_arc(actors[target_highlight].position, 22, 0, TAU, 32, Color("8ce9ff"), 3)
	if (
		visual_units.size() > selected
		and visual_units[selected].hp > 0
		and visible_to_player(selected)
	):
		draw_arc(
			positions.get(selected, center(battle.units[selected].cell)) + Vector2(0, 13),
			24,
			0,
			TAU,
			32,
			Color("ead7a0"),
			2
		)


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
		var label := "IMPACTO APÓS RESPOSTA"
		var text_width := (
			ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		)
		draw_string(
			ThemeDB.fallback_font,
			center(mark.cell) + Vector2(-text_width / 2, -30),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			Color("ffd19c")
		)
	if battle.get("meteor_window") == true:
		if skill_id == "meteor_evade" and not timeline.playing:
			for cell in battle.emergency_destinations(selected):
				draw_circle(center(cell), 6, Color("a8e7da"))
		return
	if (
		timeline.playing
		or not battle.outcome.is_empty()
		or battle.units[selected].hp <= 0
		or selected != battle.active_index
	):
		return
	if show_moves:
		for cell in battle.preview_reachable(selected):
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
		if unit.hp <= 0 or not actors.has(i) or not visible_to_player(i):
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
	if not battle.outcome.is_empty() and not timeline.playing and not cinematic_victory:
		canvas.draw_rect(Rect2(Vector2(300, 260), Vector2(600, 110)), Color(0.04, 0.05, 0.08, 0.94))
		canvas.draw_line(Vector2(320, 270), Vector2(880, 270), Color("ad9161"), 2)
		canvas.draw_string(
			font,
			Vector2(400, 325),
			battle.outcome,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			30,
			Color("ead79d")
		)
