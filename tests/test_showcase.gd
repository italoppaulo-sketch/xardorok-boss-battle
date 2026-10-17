extends SceneTree
## Capturas do viewport real e uma partida completa apresentada na cena principal.
const Support = preload("res://scripts/support/spirit_support.gd")
const MinionAI = preload("res://scripts/ai/minion_ai.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image2d := root.get_texture().get_image()
	if image2d.save_png("res://docs/capturas/" + filename + ".png") != OK:
		failures += 1
		push_error("Falha ao salvar captura " + filename)


func settle(scene: Node) -> void:
	await process_frame
	while scene.busy or (scene.battle.active_index >= 5 and scene.battle.outcome.is_empty()):
		await process_frame


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Showcase requer display real")
		quit(1)
		return
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.6).timeout
	await capture("marco4_batalha")
	scene.battle.random_outcomes = false
	scene.battle.units[1].cell = Vector2i(11, 4)
	scene.arena.reset_visuals()
	scene._select(1)
	scene._execute("fushigiri", Vector2i(12, 4))
	await create_timer(0.55).timeout
	await capture("marco4_fushigiri")
	await settle(scene)
	scene._restart()
	scene.battle.random_outcomes = false
	scene.battle.spawn_minions()
	scene.battle.events.clear()
	scene.battle.units[6].cell = Vector2i(9, 2)
	scene.battle.units[0].cell = Vector2i(9, 5)
	scene.battle.active_index = 6
	scene.arena.reset_visuals()
	scene._refresh()
	MinionAI.act(scene.battle, 6, 0)
	scene.arena.present(scene.battle.events)
	await create_timer(0.55).timeout
	await capture("marco4_laser")
	await settle(scene)
	scene._restart()
	scene.arena.capture_state()
	Support.grant(scene.battle)
	scene.arena.present(scene.battle.events)
	await create_timer(1.1).timeout
	await capture("marco4_dalamud")
	await settle(scene)
	scene._restart()
	scene.battle.rng.seed = 17
	var strategy := preload("res://tests/support/autoplayer.gd").new()
	Engine.time_scale = 4
	for turn in 600:
		if not scene.battle.outcome.is_empty():
			break
		var hero: int = scene.battle.active_index
		if hero < 5:
			scene._select(hero)
			scene.arena.capture_state()
			scene.battle.events.clear()
			strategy.play_hero(scene.battle, hero)
			scene.arena.present(scene.battle.events)
			await settle(scene)
			if not scene.battle.outcome.is_empty():
				break
		if scene.battle.outcome.is_empty():
			scene._end_round()
			await settle(scene)
	Engine.time_scale = 1
	scene._refresh()
	await create_timer(0.2).timeout
	await capture("marco4_vitoria")
	if scene.battle.outcome != "BOSS DEFEATED":
		failures += 1
		push_error("Partida visual não alcançou vitória")
	print(
		(
			"Partida completa renderizada: %s, rodada %d; falhas: %d"
			% [scene.battle.outcome, scene.battle.round_number, failures]
		)
	)
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
