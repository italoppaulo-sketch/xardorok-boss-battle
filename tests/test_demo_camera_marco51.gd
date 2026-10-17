extends SceneTree
## Vídeo técnico do viewport real. Autoplayer usa exatamente as regras de produção.
const Strategy = preload("res://tests/support/autoplayer.gd")
const FRAME_COUNT := 270
var scene: Node
var strategy := Strategy.new()
var hero_decisions := 0
var failures := 0
var frame_dir := OS.get_environment("XARDOROK_DEMO_FRAMES")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Vídeo exige framebuffer gráfico real")
		quit(1)
		return
	if frame_dir.is_empty():
		frame_dir = ProjectSettings.globalize_path("user://marco51_demo_frames")
	DirAccess.make_dir_recursive_absolute(frame_dir)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.battle.rng.seed = 17
	strategy.policy = "antimagia"
	Engine.time_scale = 1.5
	for frame in FRAME_COUNT:
		var t := float(frame) / float(FRAME_COUNT - 1)
		scene.arena.orbit.set_orbit(90 * sin(t * TAU), 1.05 - 0.30 * pow(sin(t * PI), 2), true)
		if not scene.busy and scene.battle.outcome.is_empty():
			if scene.battle.meteor_window:
				scene.arena.capture_state()
				scene.battle.events.clear()
				strategy.respond_meteor(scene.battle)
				scene.arena.present(scene.battle.events)
			elif scene.battle.active_index >= 5:
				scene._continue_turns()
			else:
				scene._select(scene.battle.active_index)
				scene.arena.capture_state()
				scene.battle.events.clear()
				strategy.play_hero(scene.battle, scene.battle.active_index)
				scene.arena.present(scene.battle.events)
				hero_decisions += 1
				if not scene.busy and not scene.battle.meteor_window:
					scene._end_round()
		await process_frame
		# A apresentação não passa automaticamente o turno de um herói após o último VFX.
		if (
			not scene.busy
			and scene.battle.active_index < 5
			and not scene.battle.meteor_window
			and scene.battle.units[scene.battle.active_index].actions == 0
		):
			scene._end_round()
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(frame_dir + "/frame_%04d.png" % frame) != OK:
			failures += 1
	Engine.time_scale = 1
	if hero_decisions == 0 or scene.battle.units[5].hp == 900:
		failures += 1
		push_error("Vídeo não registrou combate real")
	print(
		(
			"Marco5.1 demo real: %d frames; %d decisões heróis; rodada %d; HP chefe %d; falhas %d"
			% [
				FRAME_COUNT,
				hero_decisions,
				scene.battle.round_number,
				scene.battle.units[5].hp,
				failures
			]
		)
	)
	quit(1 if failures else 0)
