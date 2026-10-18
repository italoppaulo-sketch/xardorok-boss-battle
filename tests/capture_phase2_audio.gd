extends SceneTree
## Deterministic audiovisual fixture; only the test battle's HP is changed.
var scene: Node
var frames := 0
var records: Array[Dictionary] = []
var output := "/workspace/phase2-evidence/after-trace.json"


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(600, 350)
	scene = load("res://scenes/main.tscn").instantiate()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--baseline-script="):
			scene.audio.set_script(load(argument.trim_prefix("--baseline-script=")))
		if argument.begins_with("--trace="):
			output = argument.trim_prefix("--trace=")
	scene.audio.persist_settings = false
	root.add_child(scene)
	scene.arena.presentation_finished.disconnect(scene._on_presentation_finished)
	scene.battle.random_outcomes = false
	scene.audio.cue_played.connect(func(cue: String, context: Dictionary):
		records.append({"event": "cue", "cue": cue, "at": context.get("at", scene.audio.clock)}))


func _process(_delta: float) -> bool:
	frames += 1
	if frames >= 375:
		quit()
		return false
	if not is_instance_valid(scene):
		return false
	if frames in [60, 120]:
		scene.arena.capture_state()
		scene.battle.events.clear()
		scene.battle.deal_damage(2, 5, 449 if frames == 60 else 1, "true")
		scene.arena.present(scene.battle.events)
	if frames % 15 == 0 and frames <= 360:
		var record := {
			"event": "sample", "at": scene.audio.clock, "hp": scene.battle.units[5].hp,
			"visual_hp": scene.arena.visual_units[5].hp, "phase": scene.battle.boss_phase,
			"requests_accepted": scene.audio.phase_transition_count,
			"nominal_mix": scene.audio.phase_mix,
			"players": scene.audio.music.size(), "playing": scene.audio.music[0].playing,
			"voices": scene.audio.voices.map(func(v: Dictionary): return v.cue)
		}
		var playback: AudioStreamPlayback = scene.audio.music[0].get_stream_playback()
		if playback is AudioStreamPlaybackInteractive:
			record["active_clip"] = playback.get_current_clip_index()
		records.append(record)
	if frames == 360:
		FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(records, "\t"))
		scene.audio.shutdown()
	if frames == 370:
		scene.queue_free()
	return false
