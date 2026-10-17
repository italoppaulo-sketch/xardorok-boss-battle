extends SceneTree
## Oito cenários específicos do Marco 4 no viewport real. Fixtures não são partidas simuladas.
const Battle = preload("res://scripts/combat/battle.gd")
var scene: Node
var failures := 0
var scenarios := 0
var recording := false
var movie_frames := 0
var last_capture := 0.0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)


func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var image2d := root.get_texture().get_image()
	expect(image2d.get_size() == Vector2i(1200, 700), "Viewport 1200 × 700")
	expect(image2d.save_png("res://docs/capturas/" + id + ".png") == OK, "Salvar " + id)
	scenarios += 1


func settle() -> void:
	while scene.busy:
		await process_frame


func record_movie() -> void:
	while recording:
		await RenderingServer.frame_post_draw
		if Time.get_ticks_msec() * 0.001 - last_capture >= 0.1:
			last_capture = Time.get_ticks_msec() * 0.001
			root.get_texture().get_image().save_png(
				"/tmp/marco4-demo/frame_%05d.png" % movie_frames
			)
			movie_frames += 1
		await process_frame


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Requer renderização com display")
		quit(1)
		return
	if "--record-demo" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("/tmp/marco4-demo")
		recording = true
		record_movie.call_deferred()
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	await capture("marco4_hud_arena")

	# Chefe, aliado e lacaio dentro da mesma nuvem, observador exterior.
	var b: RefCounted = scene.battle
	b.random_outcomes = false
	b.spawn_minions()
	b.units[5].cell = Vector2i(10, 4)
	b.units[1].cell = Vector2i(5, 4)
	b.units[0].cell = Vector2i(9, 4)
	b.units[6].cell = Vector2i(10, 5)
	b.events.clear()
	scene.arena.reset_visuals()
	b.active_index = 5
	expect(b.use_ability(5, "smoke", b.units[5].cell), "Conjurar fumaça")
	b.active_index = 1
	scene.arena.present(b.events)
	await create_timer(0.8).timeout
	expect(
		(
			not scene.arena.actors[5].visible
			and not scene.arena.actors[0].visible
			and not scene.arena.actors[6].visible
		),
		"Oculta sprites de todos os tipos"
	)
	expect(not scene.hud.boss_hp.visible, "HUD oculta HP durante a apresentação")
	await capture("marco4_fumaca_oculta")
	await settle()

	scene._on_cell(Vector2i(8, 4))
	await settle()
	expect(
		b.player_visible(5) and scene.arena.actors[5].visible,
		"Entrada revela dentro da mesma nuvem"
	)
	await capture("marco4_fumaca_interior")

	# Antimagia remove a zona e reativa visão/indicadores.
	b.active_index = 2
	b.units[2].cell = Vector2i(6, 6)
	scene._refresh()
	scene._execute("antispell", Vector2i(10, 4))
	await settle()
	expect(b.smoke.is_empty() and scene.arena.actors[5].visible, "Antimagia revela chefe")
	await capture("marco4_antimagia")

	scene._restart()
	b = scene.battle
	b.random_outcomes = false
	b.units[5].hp = 451
	scene.arena.reset_visuals()
	b.events.clear()
	b.deal_damage(1, 5, 1, "true")
	scene.arena.present(b.events)
	await create_timer(0.35).timeout
	expect(b.boss_phase == 2 and b.phase_transition_count == 1, "Fase 2 única")
	expect("A IRA DO REI" in scene.hud.boss_label.text, "HUD acompanha transição visual")
	expect(scene.hud.boss_hp.value == 450, "HUD mostra HP no impacto da transição")
	await capture("marco4_fase2")
	await settle()

	scene._restart()
	b = scene.battle
	scene._end_round()
	await settle()
	scene._end_round()
	await create_timer(0.35).timeout
	expect(b.reactions_used == 1 and not b.meteors.is_empty(), "Reação telegráfica intermediária")
	await capture("marco4_reacao")
	await settle()

	scene._restart()
	b = scene.battle
	b.active_index = 5
	b.random_outcomes = false
	b.events.clear()
	expect(b.use_ability(5, "meteors", b.units[1].cell), "Preparar chuva de meteoros")
	b.active_index = 1
	scene.arena.present(b.events)
	await settle()
	await capture("marco4_meteoros")

	scene.hud.log_button.pressed.emit()
	await process_frame
	expect(scene.hud.log_panel.visible, "Registro expansível integrado")
	await capture("marco4_registro")
	recording = false
	scene.queue_free()
	await process_frame
	print(
		(
			"Marco 4 gráficos: %d cenários; %d falhas; frames vídeo %d"
			% [scenarios, failures, movie_frames]
		)
	)
	quit(1 if failures else 0)
