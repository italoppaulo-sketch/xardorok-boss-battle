extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
var checks := 0
var failures := 0


func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var b := Battle.new()
	b.random_outcomes = false
	b.units[1].cell = Vector2i(4, 3)
	b.units[0].cell = Vector2i(4, 1)
	var arena: Node2D = load("res://scripts/world/arena.gd").new()
	arena.battle = b
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	expect(arena.visible_to_player(0), "Aliado visível antes de aproximar da coluna")
	arena.capture_state()
	b.events.clear()
	expect(b.move_unit(1, Vector2i(2, 1)), "Movimento real válido ao lado da coluna")
	arena.present(b.events)
	for frame in 100:
		arena._process(0.025)
	expect(arena.visible_to_player(0), "REGRESSÃO: aliado não some sem fumaça após aproximação")
	expect(arena.actors[0].visible, "REGRESSÃO: nó do aliado continua desenhado")
	expect(not b.visible(b.units[1].cell, b.units[0].cell), "Paredes continuam bloqueando ataques")
	b.active_index = 3
	arena._process(0.025)
	expect(arena.actors[0].visible, "Trocar observador não precisa ressuscitar sprite sem fumaça")
	await approach_cases(arena, b)
	await smoke_cases(arena, b)
	print("Visibility Marco 5: %d checks; %d failures" % [checks, failures])
	arena.queue_free()
	await process_frame
	quit(1 if failures else 0)


func move_case(
	arena: Node2D,
	b: RefCounted,
	start: Vector2i,
	finish: Vector2i,
	neighbor: Vector2i,
	speed: float,
	step: float,
	flying: bool = false
) -> void:
	b.smoke.clear()
	b.active_index = 3 if flying else 1
	var mover: int = b.active_index
	b.units[mover].cell = start
	b.units[0].cell = neighbor
	b.units[mover].move = 8
	b.units[mover].statuses.clear()
	if flying:
		b.units[mover].statuses.flight = 3
	arena.movement_speed = speed
	arena.reset_visuals()
	var nodes := {}
	for index in arena.actors:
		nodes[index] = arena.actors[index].get_instance_id()
	var hp: int = b.units[0].hp
	var actions: int = b.units[mover].actions
	b.events.clear()
	expect(b.move_unit(mover, finish), "Caminho válido %s → %s" % [start, finish])
	arena.present(b.events)
	var always_visible := true
	var stable_nodes := true
	var coherent_position := true
	for frame in 2000:
		arena._process(step)
		for index in 5:
			always_visible = always_visible and arena.actors[index].visible
			stable_nodes = stable_nodes and nodes[index] == arena.actors[index].get_instance_id()
			coherent_position = (
				coherent_position
				and arena.actors[index].position.is_equal_approx(
					arena.positions[index] + Vector2(0, 14)
				)
			)
		if not arena.timeline.playing:
			break
	expect(
		always_visible, "Todos os aliados visíveis: velocidade %.1f / delta %.3f" % [speed, step]
	)
	expect(stable_nodes, "Aproximação preserva um nó independente para cada combatente")
	expect(coherent_position, "Nó e posição interpolada concordam em todo frame")
	expect(
		arena.positions[mover].is_equal_approx(arena.center(finish)),
		"Caminho termina antes de liberar interface"
	)
	expect(arena.routes[mover].is_empty(), "Sem waypoints residuais após apresentação")
	expect(
		b.units[0].hp == hp and b.units[mover].actions == actions,
		"Apresentação não executa dano nem ação adicional"
	)


func approach_cases(arena: Node2D, b: RefCounted) -> void:
	move_case(arena, b, Vector2i(4, 3), Vector2i(2, 1), Vector2i(4, 1), 40.0, 0.025)
	move_case(arena, b, Vector2i(3, 4), Vector2i(7, 4), Vector2i(5, 5), 480.0, 0.016)
	move_case(arena, b, Vector2i(7, 4), Vector2i(3, 4), Vector2i(5, 5), 480.0, 1.4)
	move_case(arena, b, Vector2i(1, 7), Vector2i(3, 7), Vector2i(3, 6), 65.0, 0.3, true)
	expect(arena.sorting.y_sort_enabled, "Y-sort continua habilitado para oclusão natural")
	expect(arena.actors.size() == b.units.size(), "Sem nós reutilizados ou combatentes extras")
	await process_frame


func smoke_cases(arena: Node2D, b: RefCounted) -> void:
	b.active_index = 1
	b.units[1].cell = Vector2i(5, 4)
	b.units[0].cell = Vector2i(9, 4)
	b.units[5].cell = Vector2i(10, 4)
	b.units[1].move = 6
	b.smoke.assign([{"cell": Vector2i(10, 4), "radius": 3.0, "expires": 3}])
	arena.movement_speed = 50.0
	arena.reset_visuals()
	arena._process(0.0)
	expect(
		not arena.actors[0].visible and not arena.actors[5].visible,
		"Fumaça legítima oculta aliado e chefe interiores"
	)
	expect(arena.actors[1].visible, "Observador permanece identificável")
	expect(
		not b.visible(b.units[1].cell, b.units[5].cell), "Fumaça ainda impede ataque direcionado"
	)
	b.events.clear()
	expect(b.move_unit(1, Vector2i(8, 4)), "Entrada real na fumaça")
	arena.present(b.events)
	var coherent_smoke := true
	var partial_reveal := false
	for frame in 200:
		arena._process(0.025)
		var drawn_observer: Vector2 = arena.displayed_cell(1)
		var expected: bool = Battle.Perception.presentation_line(
			drawn_observer, arena.displayed_cell(0), arena.visual_smoke
		)
		coherent_smoke = coherent_smoke and arena.actors[0].visible == expected
		if drawn_observer.x > 7.0 and drawn_observer.x < 7.9:
			partial_reveal = partial_reveal or arena.actors[0].visible
		if not arena.timeline.playing:
			break
	expect(coherent_smoke, "Ocultação usa a posição realmente desenhada em cada frame")
	expect(partial_reveal, "Entrada revela durante interpolação, sem esperar waypoint ou turno")
	expect(
		arena.actors[0].visible and arena.actors[5].visible, "Mesma nuvem revela unidades entre si"
	)
	b.smoke.clear()
	arena._apply_visual({"kind": "world", "smoke_zones": [], "marks": [], "fire_zones": []})
	arena._process(0.0)
	expect(
		arena.actors[0].visible and arena.actors[5].visible,
		"Antimagia restaura sprites sem passar turno"
	)
	expect(arena.visual_smoke.is_empty(), "Ocultação encerrada não persiste no snapshot")
	arena.reset_visuals()
	expect(
		arena.routes.is_empty() and arena.pending_spawns.is_empty(),
		"Reinício remove caminhos e nascimentos pendentes"
	)
	await process_frame
