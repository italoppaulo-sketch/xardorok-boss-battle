extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
var checks := 0
var failures := 0


func expect(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var b := Battle.new()
	b.random_outcomes = false
	b.units[5].cell = Vector2i(7, 5)
	b.spawn_minions()
	b.units[6].cell = Vector2i(7, 4)
	b.units[7].cell = Vector2i(8, 5)
	var arena: Node2D = load("res://scripts/world/arena.gd").new()
	arena.battle = b
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena._process(1.0)
	expect(b.unit_at(Vector2i(7, 4)) == 6, "Lacaio ocupa célula própria")
	expect(arena.actors[6].visible, "Lacaio atrás do chefe não desaparece")
	var feet: Vector2 = arena.actors[6].position
	expect(
		arena.pointer_cell(feet) == b.units[6].cell,
		"Base do lacaio seleciona lacaio mesmo sob corpo do chefe"
	)
	expect(
		arena.pointer_cell(arena.actors[5].position) == b.units[5].cell,
		"Base do chefe continua selecionável"
	)
	check_anchors(arena)
	await clustered_cases(arena, b)
	await movement_case(arena, b)
	check_summons()
	arena.queue_free()
	await process_frame
	print("Minions Marco 5.1: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)


func check_anchors(arena: Node2D) -> void:
	for index in arena.actors:
		var actor: Node2D = arena.actors[index]
		expect(actor.sprite.offset == Vector2(0, -54), "Âncora aprovada preservada %d" % index)
		var size: Vector2 = actor.sprite.sprite_frames.get_frame_texture("idle", 0).get_size()
		var foot: Vector2 = actor.sprite.offset - size * 0.5 + Vector2(56, 118)
		expect(foot.is_zero_approx(), "Pé do atlas coincide com origem do ator %d" % index)
		expect(
			not actor.contains_point(actor.to_global(Vector2(-55, -110))),
			"Transparência não aumenta alvo %d" % index
		)


func clustered_cases(arena: Node2D, b: RefCounted) -> void:
	var cases := [
		[Vector2i(7, 5), Vector2i(7, 4), Vector2i(8, 5)],
		[Vector2i(7, 4), Vector2i(6, 4), Vector2i(8, 4)],
		[Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 2)],
		[Vector2i(11, 2), Vector2i(10, 2), Vector2i(11, 3)]
	]
	for cells in cases:
		for i in 3:
			b.units[5 + i].cell = cells[i]
		arena.reset_visuals()
		arena._process(1.0)
		for index in range(5, 8):
			expect(arena.actors[index].visible, "Grupo junto de ruína permanece visível %d" % index)
			expect(
				arena.pointer_cell(arena.actors[index].position) == b.units[index].cell,
				"Pés selecionam unidade correta no grupo %d" % index
			)
		expect(arena.actors.size() == b.units.size(), "Um ator por unidade, sem reutilização")
	# Fumaça legítima mantém prioridade sobre qualquer área clicável.
	b.active_index = 1
	b.units[1].cell = Vector2i(4, 4)
	b.units[5].cell = Vector2i(10, 4)
	b.units[6].cell = Vector2i(10, 5)
	b.smoke.assign([{"cell": Vector2i(10, 4), "radius": 2.0, "expires": 3}])
	arena.reset_visuals()
	arena._process(0.0)
	expect(not arena.actors[6].visible, "Fumaça oculta lacaio normalmente")
	expect(
		not arena.actors[6].contains_base(arena.actors[6].global_position),
		"Base de unidade oculta não é clicável"
	)
	b.smoke.clear()
	await process_frame


func movement_case(arena: Node2D, b: RefCounted) -> void:
	b.active_index = 6
	b.units[6].cell = Vector2i(6, 4)
	b.units[6].move = 5
	b.units[7].cell = Vector2i(10, 4)
	b.units[5].cell = Vector2i(8, 5)
	b.units[0].cell = Vector2i(7, 5)
	arena.reset_visuals()
	var node_id: int = arena.actors[6].get_instance_id()
	b.events.clear()
	expect(not b.move_unit(6, b.units[0].cell), "Não entra em célula de herói")
	expect(not b.move_unit(6, b.units[5].cell), "Não entra em célula do chefe")
	expect(b.move_unit(6, Vector2i(8, 4)), "Lacaio passa entre unidades por células livres")
	arena.present(b.events)
	var visible := true
	var coherent := true
	for frame in 150:
		arena._process(0.02)
		visible = visible and arena.actors[6].visible
		coherent = (
			coherent
			and arena.actors[6].position.is_equal_approx(arena.positions[6] + Vector2(0, 14))
		)
		if not arena.timeline.playing:
			break
	expect(visible, "Lacaio não desaparece durante trajeto entre unidades")
	expect(coherent, "Nó acompanha interpolação sem deslocamento artificial")
	expect(arena.actors[6].get_instance_id() == node_id, "Movimento preserva identidade visual")
	expect(
		arena.positions[6].is_equal_approx(arena.center(b.units[6].cell)),
		"Apresentação termina na célula real"
	)
	expect(
		arena.pointer_cell(arena.actors[6].position) == b.units[6].cell,
		"Selecionável após movimento"
	)
	await process_frame


func check_summons() -> void:
	# Cerca completa: nenhum dos quatro vizinhos imediatos está livre.
	for boss_cell in [Vector2i(7, 4), Vector2i(3, 2), Vector2i(11, 2), Vector2i(3, 0)]:
		var b := Battle.new()
		b.units[5].cell = boss_cell
		var nearby: Array[Vector2i] = []
		for direction in Battle.DIRECTIONS:
			var cell: Vector2i = boss_cell + direction
			if b.inside(cell) and cell not in Battle.WALLS:
				nearby.append(cell)
		for i in nearby.size():
			b.units[i].cell = nearby[i]
		b.spawn_minions()
		b.spawn_minions()
		expect(
			b.living_minions() == 3,
			"Limite e invocação inicial preservados junto de bordas/obstáculos"
		)
		var occupied := {}
		var valid := true
		for unit in b.units:
			if unit.hp <= 0:
				continue
			valid = (
				valid
				and b.inside(unit.cell)
				and unit.cell not in Battle.WALLS
				and not occupied.has(unit.cell)
			)
			occupied[unit.cell] = true
		expect(valid, "Invocação cercada não sobrepõe unidades nem obstáculos")
		for index in range(6, b.units.size()):
			expect(
				b.distance(b.units[5].cell, b.units[index].cell) >= 2,
				"Busca expande quando células próximas estão ocupadas"
			)
