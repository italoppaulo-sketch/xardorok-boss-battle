extends SceneTree
## The original victory CanvasLayer projects the falling crown through the 2D camera.
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func run() -> void:
	root.size = Vector2i(1200, 700)
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.battle.random_outcomes = false
	scene.battle.units[1].cell = Vector2i(11, 4)
	scene.battle.units[5].hp = 1
	scene.arena.reset_visuals()
	scene.camera.target_zoom = 1.6
	scene.camera.zoom = Vector2.ONE * 1.6
	scene.camera.focus_world(Vector2(850, 350))
	await process_frame
	scene._execute("basic", scene.battle.units[5].cell)
	for frame in 1500:
		await process_frame
		if not scene.busy:
			break
	expect(scene.battle.outcome == "BOSS DEFEATED", "Golpe real vence com zoom/pan")
	expect(scene.victory.is_playing(), "Vitória preservada após golpe final")
	scene.victory.elapsed = 0
	scene.victory._update_visuals()
	var expected: Vector2 = scene.arena.get_viewport_transform() * scene.victory.crown_world_origin
	expect(
		scene.victory.crown.position.distance_to(expected) < 0.01,
		"Origem da coroa projetada pela câmera 2D"
	)
	expect(
		scene.victory.crown.scale.is_equal_approx(scene.camera.zoom),
		"Coroa acompanha escala da arena"
	)
	var previous: Vector2 = scene.victory.crown.position
	scene.camera.focus_world(Vector2(750, 300))
	await process_frame
	scene.victory.elapsed = 0
	scene.victory._update_visuals()
	expected = scene.arena.get_viewport_transform() * scene.victory.crown_world_origin
	expect(
		scene.victory.crown.position.distance_to(expected) < 0.01,
		"Pan durante vitória reprojeta coroa"
	)
	expect(
		not scene.victory.crown.position.is_equal_approx(previous),
		"Coroa não fica fixa no ponto anterior da tela"
	)
	scene.victory.elapsed = 1.7
	scene.victory._update_visuals()
	expect(
		scene.victory.title.text == "REI DAS CINZAS DERROTADO", "Faixa original aprovada mantida"
	)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		expect(
			(
				root.get_texture().get_image().save_png(
					"res://docs/capturas/marco52_vitoria_zoom.png"
				)
				== OK
			),
			"Captura real da vitória aproximada"
		)
	scene.victory.skip()
	expect(scene.victory.is_finished() and not scene.victory.is_playing(), "Vitória permite pular")
	expect(scene.arena.actors[5].sprite.speed_scale == 1, "Pular restaura velocidade visual")
	scene._restart()
	expect(
		not scene.victory.canvas.visible and scene.camera.zoom == Vector2.ONE,
		"Reiniciar limpa vitória e zoom"
	)
	print("Marco5.2 vitória/câmera: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)
