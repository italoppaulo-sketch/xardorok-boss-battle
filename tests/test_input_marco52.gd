extends SceneTree
## Mouse/keyboard events traverse the real scene and CanvasLayer, including zoom transforms.
var scene: Node
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func frames(count: int = 3) -> void:
	for frame in count:
		await process_frame


func settle() -> void:
	for frame in 1800:
		await process_frame
		if not scene.busy:
			return
	expect(false, "Apresentação termina sem referência inválida")


func click(point: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = button
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()


func screen(point: Vector2) -> Vector2:
	return scene.arena.get_global_transform_with_canvas() * point


func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	expect(
		root.get_texture().get_image().save_png("res://docs/capturas/" + name + ".png") == OK,
		"Captura real " + name
	)


func run() -> void:
	root.size = Vector2i(1200, 700)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await frames(8)
	Engine.time_scale = 4
	var b: RefCounted = scene.battle
	b.random_outcomes = false
	var initial_cells: Array = []
	for unit in b.units:
		initial_cells.append(unit.cell)
	var hud_rect: Rect2 = scene.hud.hero_buttons[0].get_global_rect()
	await click(Vector2(650, 300), MOUSE_BUTTON_WHEEL_UP)
	expect(scene.camera.target_zoom > 1, "Roda real aumenta zoom 2D")
	await create_timer(0.5).timeout
	expect(scene.camera.zoom.x > 1, "Zoom converge suavemente")
	expect(scene.hud.hero_buttons[0].get_global_rect() == hud_rect, "HUD não acompanha zoom")
	for index in b.units.size():
		expect(b.units[index].cell == initial_cells[index], "Zoom preserva posições lógicas")
	var destination := Vector2i(1, 4)
	await click(screen(scene.arena.center(destination)))
	await settle()
	expect(b.units[1].cell == destination, "Clique transformado move Kodokami após zoom")
	await key(KEY_F)
	expect(scene.camera.position != scene.camera.DEFAULT_CENTER, "F centraliza selecionado")
	await key(KEY_HOME)
	expect(
		scene.camera.zoom == Vector2.ONE and scene.camera.position == scene.camera.DEFAULT_CENTER,
		"Home restaura enquadramento imediatamente"
	)
	for direction in [-1.0, 1.0]:
		for count in 30:
			scene.camera.change_zoom(direction)
		expect(
			scene.camera.target_zoom >= 0.85 and scene.camera.target_zoom <= 1.8,
			"Limites configuráveis respeitados"
		)
	scene.camera.reset_view()
	# A dense fixture uses valid adjacent cells; the click is found in actual sprite overlap.
	b.spawn_minions()
	b.units[5].cell = Vector2i(8, 4)
	b.units[0].cell = Vector2i(7, 4)
	b.units[1].cell = Vector2i(8, 5)
	b.units[2].cell = Vector2i(6, 5)
	b.units[3].cell = Vector2i(7, 5)
	b.units[4].cell = Vector2i(6, 4)
	b.units[6].cell = Vector2i(9, 4)
	b.units[7].cell = Vector2i(9, 5)
	b.active_index = 2
	scene._select(2)
	scene.arena.reset_visuals()
	await frames(5)
	var occupied := {}
	for unit in b.units:
		expect(not occupied.has(unit.cell), "Fixture densa sem sobreposição lógica")
		occupied[unit.cell] = true
	var point := Vector2(-1, -1)
	for y in range(240, 455, 3):
		for x in range(370, 790, 3):
			var candidate := Vector2(x, y)
			if scene.arena.pick_candidates(candidate).size() > 1:
				point = candidate
				break
		if point.x >= 0:
			break
	expect(point.x >= 0, "Sprites adjacentes criam candidato múltiplo real")
	if point.x >= 0:
		await click(screen(point))
		expect(
			scene.target_selector.is_open() and scene.target_selector.candidates.size() >= 2,
			"Clique congestionado abre lista real"
		)
		await capture("marco52_selecao_contextual")
		var previous: int = scene.target_selector.cursor
		await key(KEY_TAB)
		expect(scene.target_selector.cursor != previous, "Tab alterna destaque contextual")
		await key(KEY_ESCAPE)
		expect(
			not scene.target_selector.is_open() and scene.arena.target_highlight == -1,
			"Esc fecha lista e destaque"
		)
	# Tab also opens an eligible list without pixel-perfect clicking.
	await key(KEY_TAB)
	expect(scene.target_selector.is_open(), "Tab abre alternância global de alvos visíveis")
	await key(KEY_ESCAPE)
	b.units[0].hp = 50
	scene._choose_skill("heal")
	await key(KEY_TAB)
	expect(scene.target_selector.is_open(), "Cura oferece seleção contextual de aliados")
	for index in scene.target_selector.candidates:
		expect(index < 5, "Lista de cura exclui inimigos")
	var heal_index: int = scene.target_selector.candidates.find(0)
	expect(heal_index >= 0, "Grosso ferido selecionável para cura")
	if heal_index >= 0:
		scene.target_selector.cursor = heal_index
		await key(KEY_ENTER)
		await settle()
		expect(
			b.units[0].hp == 110 and scene.selected == 2,
			"Enter confirma cura real sem trocar conjurador"
		)
	# Reopen after zoom and exclude dead and smoke-concealed units.
	b.active_index = 4
	b.units[4].actions = 1
	scene._select(4)
	scene._choose_skill("chain")
	scene.camera.change_zoom(1)
	await create_timer(0.4).timeout
	await key(KEY_TAB)
	expect(scene.target_selector.is_open(), "Magia ofensiva seleciona após zoom")
	for index in scene.target_selector.candidates:
		expect(
			index >= 5 and b.player_visible(index),
			"Lista ofensiva contém apenas inimigos elegíveis"
		)
	await key(KEY_ESCAPE)
	b.smoke.append({"cell": b.units[6].cell, "radius": 0.6, "expires": 4})
	scene.arena.capture_state()
	await frames()
	expect(not scene._eligible_target(6), "Fumaça exclui inimigo encoberto")
	var concealed: Array[int] = [6]
	scene.target_selector.open_targets(b, concealed, Vector2(600, 200))
	expect(not scene.target_selector.is_open(), "Lista não identifica alvo oculto pela fumaça")
	b.smoke.clear()
	b.events.clear()
	scene.arena.capture_state()
	var freed: Vector2i = b.units[6].cell
	scene.arena.target_highlight = 6
	b.deal_damage(4, 6, 999, "arcane")
	scene.arena.present(b.events)
	await settle()
	await create_timer(1.0).timeout
	expect(not scene.arena.actors.has(6), "Após derrota curta lacaio não tem sprite/nó de HP")
	expect(
		scene.arena.retired_minions.has(6) and scene.arena.target_highlight == -1,
		"Retirada elimina destaque e registra tombstone visual"
	)
	expect(b.unit_at(freed) == -1 and 6 not in b.initiative, "Célula e iniciativa liberadas")
	expect(not scene._eligible_target(6), "Lacaio morto não é alvo")
	var candidates: Array[int] = scene.arena.pick_candidates(scene.arena.center(freed))
	expect(6 not in candidates, "Picker exclui sprite retirado")
	b.active_index = 5
	b.spawn_minions()
	scene.arena.capture_state()
	await frames()
	expect(not scene.arena.actors.has(6), "Invocar novamente não recria morto")
	expect(
		scene.arena.actors.has(b.units.size() - 1), "Nova invocação cria nó válido com novo índice"
	)
	await capture("marco52_arena_zoom")
	scene._restart()
	b = scene.battle
	b.random_outcomes = false
	b.units[0].cell = Vector2i(8, 4)
	b.units[1].cell = Vector2i(8, 5)
	b.units[0].bonus = 0
	b.units[0].actions = 0
	b.units[0].mana = 0
	b.active_index = 5
	scene.arena.reset_visuals()
	b.events.clear()
	b.use_ability(5, "meteors", b.units[0].cell)
	b.active_index = 1
	scene.arena.present(b.events)
	await settle()
	expect(scene.hud.emergency_root.visible, "Janela de reação iminente aparece")
	expect(
		not scene.hud.emergency_guard.disabled and not scene.hud.emergency_evade.disabled,
		"RD habilita ambos sem bônus, ação ou PM"
	)
	await capture("marco52_reacao_defensiva")
	var first: int = b.response_index
	await click(scene.hud.emergency_guard.get_global_rect().get_center())
	await settle()
	expect(
		b.units[first].defensive_reaction == 0 and b.units[first].bonus == 0,
		"Clique Defender usa RD sem bônus"
	)
	for response in 8:
		if not b.meteor_window:
			break
		scene._meteor_choice("stay")
		await settle()
	scene._restart()
	expect(
		scene.arena.retired_minions.is_empty() and scene.arena.actors.size() == 6,
		"Reinício limpa nós mortos e invocações"
	)
	expect(
		scene.camera.zoom == Vector2.ONE and not scene.target_selector.is_open(),
		"Reinício limpa câmera e seleção"
	)
	Engine.time_scale = 1
	print("Marco 5.2 entrada/cena: %d verificações; %d falhas" % [checks, failures])
	scene.audio.shutdown()
	await create_timer(.15).timeout
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
