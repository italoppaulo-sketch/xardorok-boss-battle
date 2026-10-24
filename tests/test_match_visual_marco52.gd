extends SceneTree
## Partida completa real, sem alterar unidades: usa regras e eventos na cena principal.
const Strategy = preload("res://tests/support/autoplayer.gd")
var scene: Node
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for frame in 4000:
		await process_frame
		if not scene.busy:
			return
	failures += 1
	push_error("Apresentação ultrapassou limite de frames")


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Partida visual exige display gráfico")
		quit(1)
		return
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.battle.rng.seed = 17
	var strategy := Strategy.new()
	strategy.policy = "antimagia"
	Engine.time_scale = 4
	for decision in 1600:
		await process_frame
		if not scene.battle.outcome.is_empty():
			break
		if scene.busy:
			await settle()
			continue
		if scene.battle.meteor_window:
			scene.arena.capture_state()
			scene.battle.events.clear()
			strategy.respond_meteor(scene.battle)
			scene.arena.present(scene.battle.events)
			await settle()
			continue
		var actor: int = scene.battle.active_index
		if actor >= 5:
			scene._continue_turns()
			await settle()
			continue
		scene._select(actor)
		scene.arena.capture_state()
		scene.battle.events.clear()
		strategy.play_hero(scene.battle, actor)
		scene.arena.present(scene.battle.events)
		await settle()
		if not scene.battle.outcome.is_empty():
			break
		if not scene.battle.meteor_window:
			scene._end_round()
			await settle()
	Engine.time_scale = 1
	await settle()
	await create_timer(2.2).timeout
	await RenderingServer.frame_post_draw
	var image2d := root.get_texture().get_image()
	if image2d.save_png("res://docs/capturas/marco52_partida_completa.png") != OK:
		failures += 1
	if scene.battle.outcome.is_empty():
		failures += 1
		push_error("Partida completa não terminou")
	print(
		(
			"Marco5.2 partida renderizada: %s; rodada %d; falhas %d"
			% [scene.battle.outcome, scene.battle.round_number, failures]
		)
	)
	quit(1 if failures else 0)
