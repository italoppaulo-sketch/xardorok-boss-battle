extends SceneTree
## Evidência gráfica real: cena experimental completa, regras aprovadas e viewport 1200×700.
var scene: Node
var checks := 0
var failures := 0
var captures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)


func capture(id: String) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	expect(img.get_size() == Vector2i(1200, 700), "Viewport real 1200×700")
	expect(img.save_png("res://docs/capturas/" + id + ".png") == OK, "Captura real " + id)
	captures += 1


func settle() -> void:
	for frame in 1500:
		await process_frame
		if not scene.busy:
			return
	expect(false, "Apresentação termina sem bloquear controles")


func fixture() -> RefCounted:
	scene._restart()
	scene.battle.random_outcomes = false
	return scene.battle


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Teste exige display gráfico real")
		quit(1)
		return
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	var hud_rect: Rect2 = scene.hud.hero_buttons[0].get_global_rect()
	for angle in [-90.0, 0.0, 90.0]:
		scene.arena.orbit.set_orbit(angle, 1, true)
		await capture(
			"marco51_arena_%s" % ("menos90" if angle < 0 else "mais90" if angle > 0 else "zero")
		)
		expect(
			scene.hud.hero_buttons[0].get_global_rect() == hud_rect, "HUD fixo ângulo %.0f" % angle
		)
	for zoom in [0.62, 1.32]:
		scene.arena.orbit.set_orbit(25, zoom, true)
		scene.arena.orbit.focus_world(Vector3(-2, 0, 0), true)
		await capture("marco51_zoom_" + ("perto" if zoom < 1 else "longe"))
	var b: RefCounted = fixture()
	for cell in [
		Vector2i(6, 3),
		Vector2i(7, 3),
		Vector2i(8, 3),
		Vector2i(6, 4),
		Vector2i(7, 4),
		Vector2i(8, 4),
		Vector2i(8, 5)
	]:
		b.FireRules.ignite(b, cell, 0)
	scene.arena.capture_state()
	scene.arena.orbit.set_orbit(30, 0.7, true)
	scene.arena.orbit.focus_world(Vector3(0, 0, 0), true)
	await create_timer(0.2).timeout
	expect(
		scene.arena.lava_surface.cells.size() == b.fire_zones.size(),
		"Lava representa células de dano reais"
	)
	await capture("marco51_lava_organica")
	b = fixture()
	b.active_index = 5
	b.events.clear()
	expect(b.use_ability(5, "fire_shield", b.units[5].cell), "Escudo real")
	b.active_index = 1
	scene.arena.orbit.set_orbit(-40, 0.8, true)
	scene.arena.present(b.events)
	await create_timer(0.5).timeout
	await capture("marco51_escudo")
	await settle()
	b = fixture()
	b.spawn_minions()
	b.active_index = 4
	b.units[4].cell = Vector2i(8, 4)
	b.units[6].cell = Vector2i(10, 4)
	b.units[7].cell = Vector2i(10, 5)
	scene.arena.reset_visuals()
	scene.arena.orbit.set_orbit(-35, 0.9, true)
	b.events.clear()
	expect(b.use_ability(4, "chain", b.units[6].cell), "Raio encadeado real")
	scene.arena.present(b.events)
	await create_timer(0.4).timeout
	await capture("marco51_raio")
	await settle()
	b = fixture()
	b.units[0].cell = Vector2i(8, 4)
	b.units[1].cell = Vector2i(8, 5)
	b.active_index = 5
	scene.arena.reset_visuals()
	b.events.clear()
	expect(b.use_ability(5, "meteors", b.units[0].cell), "Meteoro real anuncia resposta")
	b.active_index = 1
	scene.arena.orbit.set_orbit(40, 1, true)
	scene.arena.present(b.events)
	await settle()
	expect(b.meteor_window and b.response_index >= 0, "HUD da resposta de meteoro preservado")
	await capture("marco51_meteoros")
	for step in 8:
		if not b.meteor_window:
			break
		scene._meteor_choice("stay")
		await settle()
	expect(not b.meteor_window and not b.fire_zones.is_empty(), "Impactos reais deixam incêndio")
	b = fixture()
	b.smoke.append({"cell": b.units[5].cell, "radius": 2, "expires": 9})
	scene.arena.capture_state()
	scene.arena.orbit.set_orbit(-45, 1, true)
	await create_timer(0.2).timeout
	expect(not scene.arena.billboards[5].visible, "Fumaça oculta billboard do chefe")
	await capture("marco51_fumaca")
	b = fixture()
	b.units[1].cell = Vector2i(11, 4)
	b.units[5].hp = 1
	scene.arena.reset_visuals()
	scene.arena.orbit.set_orbit(35, 1, true)
	scene._execute("basic", b.units[5].cell)
	await settle()
	await create_timer(2.4).timeout
	expect(b.outcome == "BOSS DEFEATED", "Vitória pelo golpe real na apresentação híbrida")
	await capture("marco51_vitoria")
	b = fixture()
	for hero in 5:
		b.units[hero].hp = 0
	b.check_outcome()
	scene.arena.capture_state()
	scene._refresh()
	expect(b.outcome == "GRUPO DERROTADO", "Derrota preservada")
	await capture("marco51_derrota")
	scene._restart()
	expect(
		scene.battle.units[5].hp == 900 and scene.battle.fire_zones.is_empty(),
		"Reinício sem resíduos"
	)
	print(
		"Marco5.1 gráfico: %d capturas; %d verificações; %d falhas" % [captures, checks, failures]
	)
	quit(1 if failures else 0)
