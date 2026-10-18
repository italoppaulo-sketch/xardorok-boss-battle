# gdlint: disable=max-public-methods,max-returns
extends Node
## Presentation only. Never calls combat APIs or consumes the combat RNG.
signal cue_played(cue: String, context: Dictionary)
const MAX_VOICES := 14
const PHASE_FADE_SECONDS := 1.5
const BUS_DEFAULTS := {"Master": 0.9, "Music": 0.8, "SFX": 0.8, "Ambience": 0.45, "UI": 0.7}
const BUS_TRIM := {"Master": -1.0, "Music": 0.0, "SFX": -1.0, "Ambience": -12.0, "UI": -6.0}
const CASTS := {
	"skin": "ice_form",
	"hammer": "ice_form",
	"giant": "giant",
	"dodge": "dodge",
	"fushigiri": "shadow_charge",
	"root_arrow": "bow_release",
	"ice_arrow": "bow_release",
	"energy_arrow": "energy_charge",
	"flight": "flight",
	"antispell": "dispel",
	"heal": "arcane_cast",
	"purple_fire": "violet_beam",
	"illusion": "illusion",
	"chain": "chain_charge",
	"silence": "shadow_charge",
	"smoke": "smoke",
	"meteors": "summon",
	"summon": "summon",
	"fire_shield": "fire_ignite",
	"fire_aura": "fire_ignite",
	"red_laser": "laser_charge",
	"double": "hammer_swing",
	"unarmed": "punch_air"
}
const IMPACTS := {
	"double": "hammer_hit",
	"unarmed": "punch",
	"fushigiri": "sword_slash",
	"root_arrow": "arrow_hit",
	"ice_arrow": "ice_hit",
	"energy_arrow": "energy_impact",
	"purple_fire": "arcane_hit",
	"red_laser": "laser_hit"
}
const STATES := {
	"burning": "fire_hit",
	"frozen": "ice_shards",
	"rooted": "roots",
	"silenced": "silence",
	"defense": "ice_form",
	"attack": "critical",
	"evasion": "dodge",
	"illusion": "illusion",
	"flight": "flight",
	"ice_skin": "ice_form",
	"ice_hammer": "ice_form",
	"giant": "giant",
	"fire_shield": "fire_ignite",
	"fire_aura": "fire_ignite"
}
var catalog: Dictionary
var streams := {}
var voices: Array[Dictionary] = []
var recent := {}
var music: Array[AudioStreamPlayer] = []
var music_sequence := AudioStreamInteractive.new()
var phase_request_count := 0
var music_trace: Array[Dictionary] = []
var trace_music := false
var phase_started := false
var phase_transition_count := 0
var duck_db := 0.0
var ending_db := 0.0
var ambience := AudioStreamPlayer.new()
var aura := AudioStreamPlayer.new()
var stinger := AudioStreamPlayer.new()
var arena: Node
var clock := 0.0
var phase_mix := 0.0
var phase_target := 0.0
var duck_until := 0.0
var stopped := false
var outcome := ""
var victory_music_started := false
var played: Array[Dictionary] = []
var settings := BUS_DEFAULTS.duplicate()
var muted := {}
var persist_settings := true
var local_rng := RandomNumberGenerator.new()
var capture_effect: AudioEffectCapture
var capture_samples := PackedVector2Array()
var recording := false
var last_round := 1


func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/catalog.json"))
	local_rng.seed = 61429
	for bus in BUS_DEFAULTS:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		if bus != "Master":
			AudioServer.set_bus_send(AudioServer.get_bus_index(bus), "Master")
	var has_limiter := false
	for index in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, index).resource_name == "XardorokLimiter":
			has_limiter = true
	if not has_limiter:
		var limiter := AudioEffectLimiter.new()
		limiter.resource_name = "XardorokLimiter"
		limiter.ceiling_db = -1.5
		limiter.threshold_db = -3.0
		AudioServer.add_bus_effect(0, limiter)
	for i in 1:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music.append(player)
	for player in [ambience, aura, stinger]:
		add_child(player)
	ambience.bus = "Ambience"
	aura.bus = "Ambience"
	stinger.bus = "Music"
	if persist_settings:
		var config := ConfigFile.new()
		if config.load("user://audio.cfg") == OK:
			for bus in settings:
				settings[bus] = float(config.get_value("volume", bus, settings[bus]))
				muted[bus] = bool(config.get_value("mute", bus, false))
	for bus in settings:
		set_volume(bus, settings[bus], false)
		set_mute(bus, muted.get(bus, false), false)


func bind(arena_node: Node, victory: Node) -> void:
	arena = arena_node
	arena.audio_event.connect(on_visual)
	victory.audio_cue.connect(on_cinematic)
	restart()


func _stream(cue: String) -> AudioStream:
	if not catalog.has(cue):
		push_error("Audio cue missing: " + cue)
		return null
	if not streams.has(cue):
		var resource: AudioStream = load(catalog[cue].path)
		if catalog[cue].get("loop", false):
			resource = resource.duplicate()
			resource.loop = true
		streams[cue] = resource
	return streams[cue]


func play_cue(cue: String, context: Dictionary = {}, gain_db: float = 0) -> void:
	if stopped or not catalog.has(cue):
		return
	var data: Dictionary = catalog[cue]
	var key := cue + ":" + str(context.get("source", context.get("target", -1)))
	if clock - float(recent.get(key, -100.0)) < float(data.cooldown):
		return
	recent[key] = clock
	_prune()
	if voices.size() >= MAX_VOICES:
		var lowest := 0
		for i in voices.size():
			if voices[i].priority < voices[lowest].priority:
				lowest = i
		if int(data.priority) < int(voices[lowest].priority):
			return
		voices[lowest].player.stop()
		voices[lowest].player.queue_free()
		voices.remove_at(lowest)
	var player := AudioStreamPlayer.new()
	player.stream = _stream(cue)
	player.bus = data.bus
	player.volume_db = gain_db + float(data.gain_db)
	player.pitch_scale = 1.0 if data.bus == "UI" else local_rng.randf_range(0.985, 1.015)
	add_child(player)
	player.play()
	voices.append({"player": player, "priority": int(data.priority), "cue": cue})
	var record := {"cue": cue, "at": clock, "context": context.duplicate(true)}
	played.append(record)
	if played.size() > 5000:
		played.pop_front()
	cue_played.emit(cue, record)


func _prune() -> void:
	for voice in voices.duplicate():
		if not is_instance_valid(voice.player) or not voice.player.playing:
			if is_instance_valid(voice.player):
				voice.player.queue_free()
			voices.erase(voice)


func ui(cue: String = "ui_select") -> void:
	play_cue(cue)


func set_volume(bus: String, value: float, save: bool = true) -> void:
	if not settings.has(bus):
		return
	settings[bus] = clampf(value, 0, 1)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(bus),
		linear_to_db(maxf(.0001, settings[bus])) + float(BUS_TRIM[bus])
	)
	if save and persist_settings:
		_save()


func set_mute(bus: String, value: bool, save: bool = true) -> void:
	if not settings.has(bus):
		return
	muted[bus] = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), value)
	if save and persist_settings:
		_save()


func _save() -> void:
	var config := ConfigFile.new()
	for bus in settings:
		config.set_value("volume", bus, settings[bus])
		config.set_value("mute", bus, muted.get(bus, false))
	config.save("user://audio.cfg")


func restart() -> void:
	for voice in voices:
		voice.player.stop()
		voice.player.queue_free()
	voices.clear()
	recent.clear()
	stinger.stop()
	aura.stop()
	ambience.stop()
	phase_target = 0
	phase_mix = 0
	phase_started = false
	phase_transition_count = 0
	phase_request_count = 0
	duck_db = 0
	ending_db = 0
	duck_until = 0
	outcome = ""
	victory_music_started = false
	stopped = false
	last_round = 1
	# The audio mixer owns the fade: per-frame resource volume changes are stepped,
	# not interpolated by AudioStreamSynchronized. Keep one player/transport.
	music[0].stop()
	music_sequence = AudioStreamInteractive.new()
	music_sequence.clip_count = 2
	music_sequence.set_clip_name(0, &"battle")
	music_sequence.set_clip_name(1, &"phase_two")
	music_sequence.set_clip_stream(0, _stream("battle"))
	music_sequence.set_clip_stream(1, _stream("phase_two"))
	music_sequence.initial_clip = 0
	# The independent recordings have no BPM metadata: fade_beats is seconds.
	music_sequence.add_transition(
		0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE,
		AudioStreamInteractive.TRANSITION_TO_TIME_START,
		AudioStreamInteractive.FADE_CROSS, PHASE_FADE_SECONDS
	)
	music[0].stream = music_sequence
	music[0].volume_db = 0
	music[0].play()
	_music_snapshot("restart")
	ambience.stream = _stream("ruins")
	ambience.volume_db = -2
	ambience.play()
	ui("ui_open")


func basic_cue(source: int, impact: bool) -> String:
	var casts := [
		"hammer_swing",
		"punch_air",
		"arcane_cast",
		"bow_release",
		"chain_charge",
		"hammer_swing",
		"punch_air"
	]
	var hits := [
		"hammer_hit", "punch", "arcane_hit", "arrow_hit", "chain_jump", "boss_hit", "body_hit"
	]
	return hits[clampi(source, 0, 6)] if impact else casts[clampi(source, 0, 6)]


func on_visual(event: Dictionary) -> void:
	var source: int = event.get("source", -1)
	var target: int = event.get("target", -1)
	var skill: String = event.get("sound_skill", "")
	match str(event.kind):
		"cast":
			var id: String = event.ability
			play_cue(
				basic_cue(source, false) if id == "basic" else CASTS.get(id, "arcane_cast"), event
			)
			if id in ["fushigiri", "meteors"]:
				duck_until = clock + 1.6
		"animation":
			if event.get("animation", "") == "attack_alt" and skill in ["double", "unarmed"]:
				play_cue("hammer_swing" if skill == "double" else "punch_air", event)
		"launch":
			play_cue(str(event.cue), event)
		"damage":
			_damage(event, skill, source, target)
		"link":
			play_cue("chain_jump", event)
		"heal":
			play_cue("heal", event)
		"recoil":
			play_cue("sacrifice", event, -10)
		"miss":
			play_cue("dodge", event)
		"status":
			var id: String = event.status_id
			if target != int(event.get("sound_caster", -2)) or skill.is_empty():
				play_cue(STATES.get(id, "arcane_cast"), event, -5)
		"expire":
			play_cue("land" if event.status_id == "flight" else "ui_confirm", event, -10)
		"dispel":
			# Cast already emitted the unravelling gesture; only quiet confirmation here.
			play_cue("ui_confirm", event, -8)
		"spawn":
			play_cue("minion_spawn", event, -4)
		"dissipate":
			play_cue("minion_dissolve", event, -3)
		"guard":
			play_cue("guard", event)
		"route":
			if event.get("emergency", false):
				play_cue("dodge", event)
		"step":
			play_cue("flight" if event.get("flying", false) else "step", event, -7)
		"meteor":
			play_cue("meteor_fall", event)
			duck_until = clock + 1.4
		"meteor_impact":
			play_cue("meteor_hit", event)
		"phase":
			phase_request_count += 1
			_music_snapshot("phase_request")
			if phase_started or stopped or not outcome.is_empty():
				return
			phase_started = true
			phase_transition_count += 1
			phase_target = 1
			var playback := music[0].get_stream_playback() as AudioStreamPlaybackInteractive
			playback.switch_to_clip(1)
			_music_snapshot("crossfade_requested")
			play_cue("phase", event)
		"reaction":
			play_cue("summon" if event.get("ability", "") == "command" else "warning", event, -6)
		"world":
			if event.get("marks", []).size() > arena.visual_meteors.size():
				play_cue("warning", event)
			if event.get("fire_zones", []).size() > arena.visual_fire.size():
				play_cue("fire_ignite", event, -10)
		"turn":
			play_cue("ui_confirm", event, -12)
			if arena.battle.round_number != last_round:
				last_round = arena.battle.round_number
				play_cue("ui_open", event, -8)
		"spirit":
			play_cue("illusion", event, -6)


func _damage(event: Dictionary, skill: String, source: int, target: int) -> void:
	var cause: String = event.get("cause", "")
	if cause in ["aura", "shield", "floor"] or (skill.is_empty() and event.element == "fire"):
		play_cue("fire_hit", event, -5)
	elif cause == "meteor":
		if event.get("guarded", false):
			play_cue("guard_hit", event)
	elif event.element == "ice" and source == 0 and skill in ["basic", "double"]:
		play_cue("ice_hit", event)
	elif skill != "chain":
		play_cue(
			basic_cue(source, true) if skill == "basic" else IMPACTS.get(skill, "body_hit"), event
		)
	if skill == "fushigiri" and source == 1:
		play_cue("shadow_rupture", event, -7)
	if event.get("critical", false):
		play_cue("critical", event, -8)
	if target == 5 and arena.visual_units[5].statuses.has("fire_shield"):
		play_cue("guard_hit", event, -7)
	if event.get("hp_before", 9999) <= int(event.amount):
		play_cue(
			"minion_death" if target >= 6 else ("phase" if target == 5 else "hero_death"), event, -5
		)


func on_cinematic(cue: String) -> void:
	match cue:
		"start":
			if stopped or not outcome.is_empty():
				return
			outcome = "victory"
			play_cue("phase", {}, -12)
		"crown":
			play_cue("crown")
		"title":
			if stopped or outcome != "victory" or victory_music_started:
				return
			victory_music_started = true
			stinger.stream = _stream("victory")
			stinger.play()
			cue_played.emit("victory", {"at": clock})
		"skip":
			victory_music_started = true
			stinger.stop()
			for player in music:
				player.stop()
			for voice in voices:
				voice.player.stop()
			ambience.stop()
			aura.stop()


func defeat() -> void:
	if stopped or not outcome.is_empty():
		return
	outcome = "defeat"
	cue_played.emit("defeat", {"at": clock})
	stinger.stream = _stream("defeat")
	stinger.play()
	aura.stop()


func _process(delta: float) -> void:
	clock += delta
	_prune()
	# Progress is diagnostic only; the actual fade runs per audio sample, even
	# when the render/game thread stalls. No timers or tweens control playback.
	var was_fading := phase_mix < phase_target
	phase_mix = move_toward(phase_mix, phase_target, delta / PHASE_FADE_SECONDS)
	if was_fading and phase_mix == phase_target:
		_music_snapshot("crossfade_nominal_end")
	duck_db = move_toward(duck_db, -7.0 if clock < duck_until else 0.0, delta * 20)
	ending_db = move_toward(ending_db, -80.0 if not outcome.is_empty() else 0.0, delta * 55)
	for player in music:
		player.volume_db = duck_db + ending_db
		if not outcome.is_empty() and ending_db <= -79:
			player.stop()
	if arena != null:
		var active_aura: bool = (
			arena.visual_units[5].hp > 0
			and arena.visual_units[5].statuses.has("fire_aura")
			and outcome.is_empty()
		)
		if active_aura and not aura.playing:
			aura.stream = _stream("aura_presence")
			aura.volume_db = -9
			aura.play()
		elif not active_aura:
			aura.stop()
	if recording and capture_effect != null:
		var available := capture_effect.get_frames_available()
		if available > 0:
			capture_samples.append_array(capture_effect.get_buffer(available))


func _music_snapshot(reason: String) -> void:
	if not trace_music:
		return
	var playback: AudioStreamPlaybackInteractive = null
	if music[0].has_stream_playback():
		playback = music[0].get_stream_playback() as AudioStreamPlaybackInteractive
	var clip := playback.get_current_clip_index() if playback != null else -1
	var entry := {
		"at": clock, "reason": reason,
		"phase_requests": phase_request_count, "phase_transitions": phase_transition_count,
		"target": phase_target, "nominal_mix": phase_mix, "outcome": outcome,
		"playing": music[0].playing, "player_count": music.size(),
		"active_clip": clip,
		"track": str(music_sequence.get_clip_name(clip)) if clip >= 0 else "",
		"hp": arena.visual_units[5].hp if arena != null else -1,
		"model_hp": arena.battle.units[5].hp if arena != null else -1,
		"phase": arena.battle.boss_phase if arena != null else -1,
		"stinger_playing": stinger.playing
	}
	music_trace.append(entry)
	if music_trace.size() > 512:
		music_trace.pop_front()
	print("MUSIC_TRACE ", JSON.stringify(entry))


func begin_capture() -> void:
	capture_effect = AudioEffectCapture.new()
	capture_effect.buffer_length = 1.0
	AudioServer.add_bus_effect(0, capture_effect)
	capture_samples.clear()
	recording = true


func end_capture(path: String) -> void:
	_process(0)
	recording = false
	var data := PackedByteArray()
	data.resize(capture_samples.size() * 4)
	for i in capture_samples.size():
		data.encode_s16(i * 4, int(clampf(capture_samples[i].x, -1, 1) * 32767))
		data.encode_s16(i * 4 + 2, int(clampf(capture_samples[i].y, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(AudioServer.get_mix_rate())
	stream.stereo = true
	stream.data = data
	stream.save_to_wav(path)


func shutdown() -> void:
	stopped = true
	for voice in voices:
		voice.player.stop()
		voice.player.stream = null
		voice.player.queue_free()
	voices.clear()
	for player in music + [ambience, aura, stinger]:
		player.stop()
		player.stream = null
	streams.clear()


func _exit_tree() -> void:
	shutdown()
