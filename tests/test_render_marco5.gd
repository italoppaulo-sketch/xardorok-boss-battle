extends SceneTree
## Fixtures do viewport real; não constituem partidas de balanceamento.
var scene: Node
var checks := 0
var failures := 0
var scenarios := 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var image2d := root.get_texture().get_image()
	expect(image2d.get_size() == Vector2i(1200, 700), "Viewport real 1200×700")
	expect(image2d.save_png("res://docs/capturas/" + id + ".png") == OK, "Captura " + id)
	scenarios += 1


func settle() -> void:
	for step in 1200:
		if not scene.busy:
			return
		await process_frame
	expect(false, "Apresentação encerra sem bloquear HUD")


func reset() -> RefCounted:
	scene._restart()
	scene.battle.random_outcomes = false
	return scene.battle


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Teste requer display gráfico real")
		quit(1)
		return
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	await capture("marco5_arena_hud")
	for ability in ["fire_shield", "fire_aura"]:
		var fixture: RefCounted = reset()
		fixture.active_index = 5
		fixture.events.clear()
		expect(fixture.use_ability(5, ability, fixture.units[5].cell), "Habilidade real " + ability)
		fixture.active_index = 1
		scene.arena.present(fixture.events)
		await create_timer(0.65).timeout
		await capture("marco5_" + ability)
		await settle()
	var b: RefCounted = reset()
	b.units[0].cell = Vector2i(8, 4)
	b.units[1].cell = Vector2i(8, 5)
	b.active_index = 5
	scene.arena.reset_visuals()
	b.events.clear()
	expect(b.use_ability(5, "meteors", b.units[0].cell), "Meteoro real abre resposta")
	b.active_index = 1
	scene.arena.present(b.events)
	await settle()
	expect(b.meteor_window and b.response_index >= 0, "Janela contextual acessível")
	await capture("marco5_meteoro_resposta")
	for step in 8:
		if not b.meteor_window:
			break
		scene._meteor_choice("stay")
		await settle()
	expect(not b.meteor_window and not b.fire_zones.is_empty(), "Impacto gera piso incendiado")
	await capture("marco5_piso_fogo")
	b = reset()
	b.spawn_minions()
	b.active_index = 4
	b.units[4].cell = Vector2i(8, 4)
	b.units[6].cell = Vector2i(10, 4)
	b.units[7].cell = Vector2i(10, 5)
	scene.arena.reset_visuals()
	b.events.clear()
	expect(b.use_ability(4, "chain", b.units[6].cell), "Raio real encontra múltiplos alvos")
	scene.arena.present(b.events)
	await create_timer(0.58).timeout
	await capture("marco5_raio_encadeado")
	await settle()
	b = reset()
	b.units[5].hp = 1
	b.units[1].cell = Vector2i(11, 4)
	scene.arena.reset_visuals()
	scene._execute("basic", b.units[5].cell)
	await settle()
	await create_timer(2.3).timeout
	expect(b.outcome == "BOSS DEFEATED", "Golpe final alcança vitória")
	await capture("marco5_vitoria_cinematica")
	scene.victory.skip()
	await process_frame
	scene._restart()
	expect(scene.battle.outcome.is_empty(), "Reinício após sequência")
	print(
		"Marco 5 gráficos: %d cenários; %d verificações; %d falhas" % [scenarios, checks, failures]
	)
	quit(1 if failures else 0)
