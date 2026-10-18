extends SceneTree
## External QA harness; never included in the players package.
var scene: Node
var checks := 0
var failures := 0
var resources_loaded := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func resources_at(path: String) -> void:
	for name in ResourceLoader.list_directory(path):
		var resource_path := path.path_join(name)
		if name.ends_with("/"):
			resources_at(resource_path)
		elif resource_path.get_extension() in ["png", "svg", "ttf", "ogg", "wav"]:
			check(ResourceLoader.load(resource_path) != null, "Resource: " + resource_path)
			resources_loaded += 1


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func run() -> void:
	resources_at("res://assets/")
	check(resources_loaded >= 180, "Export contains sprites, font and audio")
	scene = load("res://scenes/main.tscn").instantiate()
	scene.audio.persist_settings = false
	root.add_child(scene)
	await process_frame
	var audio: Node = scene.audio
	check(scene.battle.units[5].hp == 900, "Normal battle startup")
	check(audio.music.size() == 1 and audio.music[0].playing, "One music transport")
	check(audio.catalog.size() == 63, "Complete approved audio catalogue")
	for cue in audio.catalog:
		check(audio._stream(cue) != null, "Audio loads: " + cue)
	await key(KEY_M)
	check(AudioServer.is_bus_mute(0), "M toggles master mute")
	await key(KEY_M)
	check(not AudioServer.is_bus_mute(0), "M restores master audio")
	# End the opening hero's turn using the real input handler.
	var serial: int = scene.battle.turn_serial
	await key(KEY_SPACE)
	check(scene.battle.turn_serial > serial, "Space ends the hero turn")
	scene._restart()
	await process_frame
	# Exact threshold and overkill across the threshold use production damage/phase rules.
	var b: RefCounted = scene.battle
	b.random_outcomes = false
	b.events.clear()
	b.deal_damage(2, 5, 450, "true")
	check(b.units[5].hp == 450 and b.boss_phase == 2, "450 HP activates phase two")
	var phase_events := 0
	for event in b.events:
		if event.kind == "phase":
			phase_events += 1
			audio.on_visual(event)
	check(phase_events == 1 and audio.phase_transition_count == 1, "One transition at threshold")
	for duplicate in 10:
		audio.on_visual({"kind": "phase"})
	check(audio.phase_transition_count == 1, "Duplicate phase notifications ignored")
	for frame in 100:
		audio._process(.02)
	check(is_equal_approx(audio.phase_mix, 1), "Crossfade reaches phase two")
	await create_timer(1.8).timeout
	check(audio.music[0].get_stream_playback().get_current_clip_index() == 1, "Native phase two playback")
	audio.set_volume("Music", .42, false)
	audio.set_mute("Music", true, false)
	scene._restart()
	check(audio.phase_transition_count == 0 and audio.phase_target == 0, "Restart clears latch")
	check(audio.settings.Music == .42 and audio.muted.Music, "Restart preserves volume/mute")
	audio.set_mute("Music", false, false)
	b = scene.battle
	b.random_outcomes = false
	b.events.clear()
	b.deal_damage(2, 5, 500, "true")
	check(b.units[5].hp == 400 and b.boss_phase == 2, "Damage crosses 450 HP directly")
	for event in b.events:
		if event.kind == "phase":
			audio.on_visual(event)
	check(audio.phase_transition_count == 1, "One transition after restart")
	audio.defeat()
	check(audio.stinger.playing and audio.outcome == "defeat", "Defeat plays approved music")
	audio.on_visual({"kind": "phase"})
	check(audio.phase_transition_count == 1, "Terminal outcome rejects late phase")
	scene._restart()
	scene.victory.start()
	check(audio.outcome == "victory", "Victory cinematic starts audio ending")
	scene.victory._process(1.01)
	scene.victory._process(.05)
	check(audio.stinger.playing, "Crown/title trigger victory fanfare")
	check(scene.victory.title.text == "REI DAS CINZAS DERROTADO", "Approved victory title")
	scene.victory.skip()
	check(not audio.stinger.playing and not audio.music[0].playing, "Skip cleans music")
	scene._restart()
	check(audio.music[0].playing and not audio.stinger.playing, "Restart has only battle music")
	print("Export QA: %d checks; %d resources; %d failures" % [checks, resources_loaded, failures])
	audio.shutdown()
	await create_timer(.2).timeout
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
