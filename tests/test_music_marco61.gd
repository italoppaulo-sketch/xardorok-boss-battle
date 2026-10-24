extends SceneTree
var checks := 0
var failures := 0


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var audio: Node = load("res://scripts/audio/battle_audio.gd").new()
	audio.persist_settings = false
	root.add_child(audio)
	audio.set_process(false)
	audio.restart()
	check(audio.music.size() == 1, "Single synchronized transport")
	var transport: AudioStreamPlayback = audio.music[0].get_stream_playback()
	check(audio.music_layers.stream_count == 2, "Two approved layers")
	var first: AudioStream = audio.music_layers.get_sync_stream(0)
	var second: AudioStream = audio.music_layers.get_sync_stream(1)
	check(is_equal_approx(first.get_length(), second.get_length()), "Loop lengths match")
	check(first.loop and second.loop, "Both approved arrangements loop")
	audio.on_visual({"kind": "phase"})
	for frame in 150:
		audio._process(.01)
		var sum_gain := (
			db_to_linear(audio.music_layers.get_sync_stream_volume(0))
			+ db_to_linear(audio.music_layers.get_sync_stream_volume(1))
		)
		check(absf(sum_gain - 1) < .0001, "Complementary gain without crossfade hole")
		check(is_zero_approx(audio.music[0].volume_db), "Transformation does not duck music")
		if frame % 20 == 0:
			audio.on_visual({"kind": "phase"})
	check(audio.phase_transition_count == 1, "Repeated phase events cannot restart fade")
	check(audio.music[0].get_stream_playback() == transport, "Phase does not recreate playback")
	check(is_equal_approx(audio.phase_mix, 1), "Fade completes in 1.5 seconds")
	check(
		audio.played.filter(func(e: Dictionary): return e.cue == "phase").size() == 1,
		"One transformation cue"
	)
	audio.music[0].seek(first.get_length() - .2)
	await create_timer(.6).timeout
	check(audio.music[0].playing, "Transport survives loop boundary")
	check(audio.music[0].get_playback_position() < 1, "Loop wraps to start")
	audio.restart()
	check(audio.phase_transition_count == 0 and not audio.phase_started, "Restart clears latch")
	check(audio.music[0].get_stream_playback() != transport, "Restart creates one fresh playback")
	audio.set_volume("Music", .37, false)
	audio.set_mute("Music", true, false)
	audio.on_visual({"kind": "phase"})
	audio._process(2)
	check(audio.phase_mix == 1 and audio.muted.Music, "Muted transition advances once")
	audio.set_mute("Music", false, false)
	check(audio.settings.Music == .37, "Volume survives unmute")
	audio.defeat()
	audio._process(2)
	check(not audio.music[0].playing, "Defeat ends battle transport")
	audio.on_visual({"kind": "phase"})
	check(audio.phase_transition_count == 1, "No phase after outcome")
	audio.restart()
	audio.shutdown()
	audio.on_visual({"kind": "phase"})
	check(audio.phase_transition_count == 0, "No phase after shutdown")
	print("Music Marco 6.1: %d checks; %d failures" % [checks, failures])
	await create_timer(.2).timeout
	audio.queue_free()
	await process_frame
	quit(1 if failures else 0)
