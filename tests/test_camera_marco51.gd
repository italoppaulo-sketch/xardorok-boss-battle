extends SceneTree
## Protótipo isolado: cliques reais atravessam a câmera e o controlador aprovado.
var scene: Node
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func frames(count := 3) -> void:
	for step in count:
		await process_frame
	await physics_frame


func settle() -> void:
	for step in 1200:
		await process_frame
		if not scene.busy:
			return
	expect(false, "Cronologia da apresentação encerra")


func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()


func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	await frames()


func fixture() -> void:
	scene._restart()
	var b: RefCounted = scene.battle
	b.random_outcomes = false
	b.units[1].cell = Vector2i(6, 4)
	b.units[4].cell = Vector2i(4, 2)
	b.units[5].cell = Vector2i(8, 4)
	scene.arena.reset_visuals()
	scene._refresh()
	await frames()


func run() -> void:
	var entry := (
		"res://scenes/experimental/camera_lab.tscn"
		if OS.get_cmdline_user_args().has("--prototype")
		else "res://scenes/main.tscn"
	)
	scene = load(entry).instantiate()
	root.add_child(scene)
	await frames(5)
	var a: Node = scene.arena
	expect(a.orbit.camera is Camera3D, "Experimento possui profundidade Camera3D real")
	expect(a.world_view.own_world_3d, "Arena tem mundo tridimensional independente")
	var hud_before: Rect2 = scene.hud.hero_buttons[1].get_global_rect()
	for angle in [-90.0, 0.0, 90.0]:
		for zoom in [0.62, 1.0, 1.32]:
			await fixture()
			var destination := Vector2i(6, 5) if angle == 0 else Vector2i(5 if angle < 0 else 7, 4)
			scene.battle.units[5].cell = (
				destination + (Vector2i.RIGHT if angle == 0 else Vector2i.DOWN)
			)
			a.reset_visuals()
			a.orbit.set_orbit(angle, zoom, true)
			await frames()
			var tag := "ângulo %.0f zoom %.2f" % [angle, zoom]
			expect(is_equal_approx(a.orbit.yaw_degrees, angle), "Yaw " + tag)
			expect(is_equal_approx(a.orbit.zoom_factor, zoom), "Zoom " + tag)
			expect(
				a.pick_ground(a.project_cell(destination)) == destination,
				"Projeção reversível " + tag
			)
			expect(a.pick_unit(a.screen_position(1)) == 1, "Seleção espacial " + tag)
			var logical_foot: Vector3 = (
				a.billboards[1].position - a.orbit.camera.global_basis.y * 1.6
			)
			expect(
				logical_foot.is_equal_approx(a.displayed_world(1)),
				"Âncora billboard coincide com célula " + tag
			)
			var body_point: Vector2 = a.project_world(
				a.displayed_world(1) + a.orbit.camera.global_basis.y * 0.9
			)
			expect(a.pick_unit(body_point) == 1, "Alfa do corpo seleciona herói " + tag)
			scene._select(0)
			await click(body_point)
			expect(scene.selected == 1, "Clique seleciona Kodokami " + tag)
			await click(a.project_cell(destination))
			expect(scene.battle.units[1].cell == destination, "Clique movimenta célula real " + tag)
			var hp: int = scene.battle.units[5].hp
			scene._set_mode("attack")
			await click(a.screen_position(5))
			expect(scene.battle.units[5].hp < hp, "Clique ataca alvo real " + tag)
			expect(scene.battle.units[1].actions == 0, "Combate consome ação aprovada " + tag)
			expect(
				scene.hud.hero_buttons[1].get_global_rect() == hud_before,
				"HUD permanece fixo " + tag
			)
			expect(
				a.billboards[1] is Sprite3D and a.actors[1].sprite is AnimatedSprite2D,
				"Sprite 2D aprovado em billboard " + tag
			)
	await fixture()
	var clustered: RefCounted = scene.battle
	clustered.active_index = 5
	expect(
		clustered.use_ability(5, "summon", clustered.units[5].cell),
		"Invocação real prepara agrupamento 3D"
	)
	clustered.active_index = 1
	clustered.units[0].cell = Vector2i(6, 4)
	clustered.units[1].cell = Vector2i(6, 3)
	clustered.units[5].cell = Vector2i(7, 5)
	clustered.units[6].cell = Vector2i(7, 4)
	clustered.units[7].cell = Vector2i(8, 4)
	a.reset_visuals()
	for angle in [-90.0, 0.0, 90.0]:
		for zoom in [0.62, 1.0, 1.32]:
			a.orbit.set_orbit(angle, zoom, true)
			await frames()
			for index in [0, 5, 6, 7]:
				expect(
					a.pick_unit(a.screen_position(index)) == index,
					"Agrupados: base unit %d yaw %.0f zoom %.2f" % [index, angle, zoom]
				)
	await fixture()
	a.orbit.reset_view(true)
	var action_before: int = scene.battle.units[1].actions
	var button := InputEventMouseButton.new()
	button.position = Vector2(600, 350)
	button.global_position = button.position
	button.button_index = MOUSE_BUTTON_RIGHT
	button.pressed = true
	root.push_input(button, true)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(700, 350)
	motion.global_position = motion.position
	motion.relative = Vector2(100, 0)
	root.push_input(motion, true)
	button.pressed = false
	root.push_input(button, true)
	await frames()
	expect(a.orbit.target_yaw < 0, "Arrastar direito orbita horizontalmente")
	button.button_index = MOUSE_BUTTON_WHEEL_UP
	button.pressed = true
	root.push_input(button, true)
	await frames()
	expect(a.orbit.target_zoom < 1, "Roda aproxima câmera")
	expect(scene.battle.units[1].actions == action_before, "Controles de câmera não gastam ação")
	var focus_before: Vector3 = a.orbit.target_focus
	button.button_index = MOUSE_BUTTON_MIDDLE
	button.pressed = true
	root.push_input(button, true)
	motion.relative = Vector2(30, 20)
	root.push_input(motion, true)
	button.pressed = false
	root.push_input(button, true)
	await frames()
	expect(a.orbit.target_focus != focus_before, "Arrastar meio desloca foco")
	await key(KEY_F)
	expect(is_equal_approx(a.orbit.target_focus.x, -1), "F centraliza no herói selecionado")
	a.orbit.set_orbit(-180, 0.1, true)
	expect(
		a.orbit.yaw_degrees == -90 and a.orbit.zoom_factor == 0.62, "Limites inferiores da câmera"
	)
	a.orbit.set_orbit(180, 5, true)
	expect(
		a.orbit.yaw_degrees == 90 and a.orbit.zoom_factor == 1.32, "Limites superiores da câmera"
	)
	await key(KEY_HOME)
	a.orbit.snap()
	expect(a.orbit.yaw_degrees == 0 and a.orbit.zoom_factor == 1, "Home restaura câmera")
	scene.battle.smoke.append({"cell": scene.battle.units[5].cell, "radius": 1, "expires": 9})
	a.capture_state()
	for angle in [-90.0, 0.0, 90.0]:
		a.orbit.set_orbit(angle, 1.0, true)
		await frames()
		expect(not a.visible_to_player(5), "Fumaça preserva ocultação %.0f" % angle)
		expect(a.pick_unit(a.screen_position(5)) != 5, "Rotação não seleciona oculto %.0f" % angle)
	await key(KEY_R)
	expect(
		scene.battle.smoke.is_empty() and scene.battle.units.size() == 6,
		"Reinício limpa modelo e efeitos"
	)
	expect(
		scene.battle.units[5].hp == 900 and scene.battle.active_index == 1,
		"Reinício preserva HP e iniciativa aprovados"
	)
	var same_battle: RefCounted = scene.battle
	scene.battle.units[1].mana = 57
	scene.battle.units[1].actions = 0
	scene.battle.units[1].move = 3
	scene.battle.apply_status(1, "evasion", 2)
	var model_before: Array = scene.battle.units.duplicate(true)
	await key(KEY_F2)
	expect(
		scene.battle == same_battle and scene.battle.units == model_before,
		"F2 conserva instância e recursos do motor"
	)
	expect(not scene.arena.has_method("project_cell"), "F2 restaura apresentação 2D original")
	await key(KEY_F2)
	expect(
		scene.battle == same_battle and scene.battle.units == model_before,
		"Volta 2.5D conserva estado lógico"
	)
	expect(scene.arena.has_method("project_cell"), "F2 retorna à câmera híbrida")
	await key(KEY_R)
	expect(
		(
			scene.battle.units[1].mana == 100
			and scene.battle.units[1].actions == 1
			and not scene.battle.has_status(1, "evasion")
		),
		"Reinício após alternância limpa recursos e estados"
	)
	print("Camera Marco5.1: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)
