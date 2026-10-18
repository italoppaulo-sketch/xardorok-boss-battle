extends SceneTree
## Real production battle; conservative smoke demonstration / seed 42.
const Strategy = preload("res://tests/support/smoke_capture_strategy.gd")
var scene: Node
var failures := 0
var trace: Array[Dictionary] = []
var boss_damage: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for frame in 4000:
		await process_frame
		if not scene.busy:
			return
	failures += 1
	push_error("Presentation timeout")


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Capture requires a real graphical viewport")
		quit(1)
		return
	scene = load("res://scenes/main.tscn").instantiate()
	scene.audio.persist_settings = false
	root.add_child(scene)
	scene.audio.cue_played.connect(
		func(cue: String, event: Dictionary):
			trace.append({"cue": cue, "at": event.get("at", scene.audio.clock)})
	)
	scene.arena.audio_event.connect(
		func(event: Dictionary):
			if event.kind == "damage" and event.get("target", -1) == 5:
				boss_damage.append(
					{
						"at": scene.audio.clock,
						"hp_before": event.get("hp_before", -1),
						"amount": event.amount
					}
				)
	)
	await process_frame
	scene.battle.rng.seed = 42
	var strategy := Strategy.new()
	strategy.policy = "agressivo"
	await create_timer(1.5).timeout
	for decision in 1600:
		await process_frame
		if not scene.battle.outcome.is_empty():
			break
		if scene.busy:
			await settle()
			continue
		if scene.battle.meteor_window:
			await create_timer(.55).timeout
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
		if not scene.battle.smoke.is_empty():
			await create_timer(2.5).timeout
		scene.arena.capture_state()
		scene.battle.events.clear()
		strategy.play_hero(scene.battle, actor)
		scene.arena.present(scene.battle.events)
		await settle()
		if not scene.battle.outcome.is_empty():
			break
		if not scene.battle.meteor_window:
			await create_timer(.25).timeout
			scene._end_round()
			await settle()
	await settle()
	await create_timer(8.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/marco61/vitoria.png")
	var required := [
		"hammer_hit",
		"sword_slash",
		"bow_release",
		"arcane_cast",
		"chain_jump",
		"minion_spawn",
		"laser_emit",
		"meteor_hit",
		"phase",
		"crown",
		"victory"
	]
	for cue in required:
		if not trace.any(func(event: Dictionary): return event.cue == cue):
			failures += 1
			push_error("Missing audiovisual cue " + cue)
	if scene.battle.outcome != "BOSS DEFEATED":
		failures += 1
	for entry in strategy.audit:
		if entry.executed and entry.offensive and entry.smoke_count > 0:
			failures += 1
	if strategy.dispelled_clouds < 1:
		failures += 1
	if scene.audio.phase_transition_count != 1:
		failures += 1
	var report := {
		"phase_transition_count": scene.audio.phase_transition_count,
		"boss_damage": boss_damage,
		"policy": "agressivo, suspend attacks until smoke is dispelled",
		"audit": strategy.audit,
		"dispelled_clouds": strategy.dispelled_clouds,
		"seed": 42,
		"outcome": scene.battle.outcome,
		"rounds": scene.battle.round_number,
		"failures": failures,
		"trace": trace
	}
	var file := FileAccess.open("res://docs/marco61/full_match.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(
		(
			"Marco6 actual AV match: %s; round %d; %d failures; %d cues"
			% [scene.battle.outcome, scene.battle.round_number, failures, trace.size()]
		)
	)
	scene.audio.shutdown()
	await create_timer(.2).timeout
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
