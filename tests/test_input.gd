extends SceneTree
var failures := 0
var tested_scene: Node


func expect(value: bool, text: String) -> void:
	if value:
		print("PASS: ", text)
	else:
		failures += 1
		push_error(text)


func _initialize() -> void:
	call_deferred("run")


func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	while tested_scene.busy:
		await process_frame


func key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	while tested_scene.busy:
		await process_frame


func run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	tested_scene = scene
	root.add_child(scene)
	await process_frame
	await click(Vector2(982, 88))
	expect(scene.selected == 2, "Mouse no botão seleciona Cassandra")
	scene.battle.units[0].hp = 50
	await click(Vector2(980, 326))
	expect(scene.mode == "heal", "Mouse no botão escolhe Cura")
	await click(scene.arena.center(scene.battle.units[0].cell))
	expect(
		scene.selected == 2 and scene.battle.units[0].hp == 110,
		"Mouse na arena cura aliado sem selecionar outro herói"
	)
	await key(KEY_1)
	expect(scene.selected == 0, "Tecla 1 seleciona Grosso após clicar no menu")
	await click(scene.arena.center(Vector2i(3, 2)))
	expect(scene.battle.units[0].cell == Vector2i(3, 2), "Mouse move herói pela arena")
	await key(KEY_SPACE)
	expect(scene.battle.round_number == 2, "Espaço encerra rodada após interação com interface")
	await key(KEY_4)
	await click(Vector2(980, 412))
	expect(scene.battle.has_status(3, "flight"), "Mouse ativa Botas Mágicas")
	await key(KEY_R)
	expect(
		scene.battle.round_number == 1 and not scene.battle.has_status(3, "flight"),
		"Atalho R reinicia e remove voo"
	)
	# Verifica limites reais calculados pelo tema, não apenas dimensões declaradas.
	for button in scene.hud.hero_buttons:
		expect(button.position.x + button.size.x <= 372, "Botão de herói cabe no painel")
	for button in scene.hud.skill_buttons:
		expect(
			button.position.y + button.size.y <= 420, "Botão de habilidade cabe na área reservada"
		)
	expect(
		(
			scene.hud.description.position.y + scene.hud.description.size.y
			<= scene.hud.end_button.position.y
		),
		"Descrição não cobre o botão de encerrar"
	)
	scene.queue_free()
	await process_frame
	print("Falhas: ", failures)
	quit(1 if failures else 0)
