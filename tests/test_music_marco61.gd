extends SceneTree
## Phase 2 regression: production event path plus actual native PCM mixing.
var checks := 0
var failures := 0
var scene: Node
var audio: Node


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func _initialize() -> void:
	call_deferred("finish")


func finish() -> void:
	await run()
	await process_frame
	quit(1 if failures else 0)


func reset() -> void:
	scene._restart()
	scene.battle.random_outcomes = false
	scene.battle.events.clear()


func damage(amount: int) -> void:
	scene.arena.capture_state()
	scene.battle.events.clear()
	scene.battle.deal_damage(2, 5, amount, "true")
	scene.arena.present(scene.battle.events)
	for frame in 200:
		scene.arena._process(.05)
		if not scene.arena.timeline.playing:
			break


func transport() -> AudioStreamPlaybackInteractive:
	return audio.music[0].get_stream_playback() as AudioStreamPlaybackInteractive


func run() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	scene.audio.persist_settings = false
	root.add_child(scene)
	audio = scene.audio
	audio.set_process(false)
	scene.set_process(false)
	scene.arena.set_process(false)
	scene.arena.presentation_finished.disconnect(scene._on_presentation_finished)
	reset()
	check(audio.music.size() == 1 and audio.music[0].playing, "1. One battle transport")
	check(audio.music_sequence.initial_clip == 0 and not audio.phase_started, "1. Phase 1 start")
	var first: AudioStream = audio.music_sequence.get_clip_stream(0)
	var second: AudioStream = audio.music_sequence.get_clip_stream(1)
	check(first.loop and second.loop, "Both approved recordings loop")
	check(second.get_length() > 30 and first != second, "Distinct full-length phase 2 composition")
	check(audio.catalog.phase_two.path.ends_with("phase_two_distinct.ogg"), "Rejected percussion overlay is not the active recording")
	check(is_zero_approx(first.bpm), "Fade duration uses seconds, not BPM")
	check(audio.music_sequence.get_transition_to_time(0, 1) == AudioStreamInteractive.TRANSITION_TO_TIME_START, "Distinct composition starts at its first phrase")
	check(audio.music_sequence.get_transition_fade_mode(0, 1) == AudioStreamInteractive.FADE_CROSS, "Native mixer crossfade")
	check(is_equal_approx(audio.music_sequence.get_transition_fade_beats(0, 1), 1.5), "Existing fade duration preserved")
	damage(449)
	check(scene.battle.units[5].hp == 451 and scene.battle.boss_phase == 1, "2. 451 HP remains phase 1")
	check(audio.phase_transition_count == 0, "2. No early music request")
	damage(1)
	check(scene.battle.units[5].hp == 450 and scene.battle.boss_phase == 2, "3. Exact 450 HP phase event")
	check(audio.phase_transition_count == 1, "3. One music transition via arena signal")
	var active := transport()
	for duplicate in 20:
		audio.on_visual({"kind": "phase"})
	check(audio.phase_transition_count == 1 and audio.phase_request_count == 21, "5. Same-frame events latch once")
	check(transport() == active, "5. No playback replacement")
	await create_timer(1.8).timeout
	check(transport().get_current_clip_index() == 1, "6. Native audio advances without game _process")
	check(transport() == active and audio.music[0].playing, "6. Phase 2 stable transport")

	reset()
	damage(700)
	check(scene.battle.units[5].hp == 200 and audio.phase_transition_count == 1, "4. Damage skips threshold once")
	audio._process(.4)
	audio.set_volume("Music", .37, false)
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(.37)), "11. Volume changes during fade")
	audio.set_mute("Music", true, false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "12. Mute during fade")
	audio.set_mute("Music", false, false)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and audio.settings.Music == .37, "12. Unmute preserves volume")
	reset()
	check(not audio.phase_started and audio.phase_mix == 0 and audio.phase_transition_count == 0, "7. Restart cancels fade state")
	check(audio.music_sequence.initial_clip == 0 and audio.music[0].playing and not audio.stinger.playing, "7. Restart restores phase 1 exclusively")
	check(audio.settings.Music == .37, "7. Restart preserves user volume")
	audio.on_visual({"kind": "phase"})
	await create_timer(1.8).timeout
	check(transport().get_current_clip_index() == 1, "Phase 2 before restart")
	reset()
	await process_frame
	check(transport().get_current_clip_index() == 0, "8. Restart after phase 2 restores clip 0")

	for finish_fade in [false, true]:
		reset()
		audio.on_visual({"kind": "phase"})
		if finish_fade:
			await create_timer(1.8).timeout
		audio.on_cinematic("start")
		audio.on_cinematic("title")
		var fanfare: AudioStreamPlayback = audio.stinger.get_stream_playback()
		audio.on_cinematic("title")
		check(audio.stinger.get_stream_playback() == fanfare, "9. Duplicate victory title cannot restart fanfare")
		audio._process(2)
		check(audio.outcome == "victory" and not audio.music[0].playing and audio.stinger.playing, "9. Victory during/after fade replaces battle")
		check(audio.stinger.stream == audio._stream("victory"), "9. Approved victory recording")
		audio.on_visual({"kind": "phase"})
		check(audio.phase_transition_count == 1, "9. Victory rejects late phase events")
		audio.on_cinematic("skip")
		audio.on_cinematic("title")
		check(not audio.stinger.playing, "9. Late title after skip cannot restart music")
	reset()
	audio.on_visual({"kind": "phase"})
	audio.defeat()
	var defeat_playback: AudioStreamPlayback = audio.stinger.get_stream_playback()
	audio.defeat()
	audio.on_cinematic("start")
	audio.on_cinematic("title")
	audio._process(2)
	check(audio.outcome == "defeat" and not audio.music[0].playing, "10. Defeat is terminal")
	check(audio.stinger.stream == audio._stream("defeat") and audio.stinger.get_stream_playback() == defeat_playback, "10. Approved defeat music, no duplicate restart")
	await pcm_regression()
	audio.shutdown()
	audio.on_visual({"kind": "phase"})
	audio.defeat()
	check(not audio.music[0].playing and not audio.stinger.playing, "Shutdown rejects subsequent music")
	await create_timer(.2).timeout
	scene.queue_free()
	await process_frame
	print("Music Phase 2: %d checks; %d failures; all 12 requested scenarios" % [checks, failures])
	scene = null
	audio = null


func pcm_regression() -> void:
	reset()
	audio.music[0].stop()
	# Verify native gain interpolation using known constant PCM; no gameplay-frame
	# processing occurs during the fade. A frame-driven synchronized fade fails this.
	for i in 2:
		var pcm := AudioStreamWAV.new()
		pcm.format = AudioStreamWAV.FORMAT_16_BITS
		pcm.mix_rate = 44100
		var data := PackedByteArray()
		data.resize(882000)
		for sample in 441000:
			data.encode_s16(sample * 2, 3277 if i == 0 else 16384)
		pcm.data = data
		audio.music_sequence.set_clip_stream(i, pcm)
	var playback: AudioStreamPlaybackInteractive = audio.music_sequence.instantiate_playback()
	playback.start()
	var warm := playback.mix_audio(1, 44100)
	var previous: float = warm[-1].x
	playback.switch_to_clip(1)
	var max_jump := 0.0
	for block in 400:
		var samples := playback.mix_audio(1, 256)
		for sample in samples:
			max_jump = maxf(max_jump, absf(sample.x - previous))
			previous = sample.x
	check(max_jump < .00003, "PCM fade has no frame-sized gain steps")
	check(absf(previous - .5) < .001, "PCM reaches phase 2 without _process")
	check(playback.get_current_clip_index() == 1, "PCM mixer selects phase 2")
	print("PCM max adjacent step: ", max_jump)
	playback.stop()
	# Decode the real graph beyond both loop boundaries, including a phase switch
	# across the seam. Verify non-silence and transport survival, not just a PID.
	reset()
	audio.music[0].stop()
	playback = audio.music_sequence.instantiate_playback()
	playback.start()
	var frames := 0
	var rate := int(AudioServer.get_mix_rate())
	var switched := false
	var minimum_rms := 1.0
	var duration: float = audio.music_sequence.get_clip_stream(1).get_length()
	while frames < rate * (89 + duration):
		if not switched and frames >= rate * 87:
			playback.switch_to_clip(1)
			switched = true
		var samples := playback.mix_audio(1, 4096)
		var power := 0.0
		for sample in samples:
			power += sample.length_squared() / 2
		if frames > rate * 86:
			minimum_rms = minf(minimum_rms, sqrt(power / samples.size()))
		frames += samples.size()
	check(playback.is_playing() and playback.get_current_clip_index() == 1, "Real phase 2 survives loop and transition")
	check(minimum_rms > .001, "No silent audio block across real loop/transition")
	print("Loop minimum block RMS: ", minimum_rms)
	playback.stop()
