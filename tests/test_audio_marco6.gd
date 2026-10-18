extends SceneTree
## Exercises real combat events through the production visual/audio timeline.
const Battle = preload("res://scripts/combat/battle.gd")
var scene: Node
var checks := 0
var failures := 0
var coverage := {}


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func settle() -> void:
	# Manual presentation clock for fast headless checks; audiovisual capture uses real time.
	for i in 90:
		scene.audio._process(.05)
		scene.arena._process(.05)
		if not scene.arena.timeline.playing:
			break
	await process_frame


func fixture(caster: int) -> RefCounted:
	var b := Battle.new()
	b.random_outcomes = false
	if caster >= 6:
		b.spawn_minions()
	for i in b.units.size():
		b.units[i].cell = Vector2i(i, 0)
	b.units[caster].cell = Vector2i(6, 4)
	b.units[0 if caster >= 5 else 5].cell = Vector2i(7, 4)
	b.active_index = caster
	scene.battle = b
	scene.arena.battle = b
	scene.victory.configure(scene.arena, b)
	scene.arena.reset_visuals()
	scene.audio.restart()
	scene.audio.played.clear()
	return b


func count(cue: String) -> int:
	var n := 0
	for played in scene.audio.played:
		if played.cue == cue:
			n += 1
	return n


func ability(caster: int, id: String) -> void:
	var b := fixture(caster)
	if id == "chain":
		b.spawn_minions()
		b.units[6].cell = Vector2i(8, 4)
		b.units[7].cell = Vector2i(9, 4)
		scene.arena.capture_state()
	if id == "heal":
		b.units[0].hp = 50
		b.units[0].cell = Vector2i(7, 4)
		b.units[5].cell = Vector2i(12, 4)
		scene.arena.capture_state()
	var cell: Vector2i = b.units[caster].cell
	var skill: Dictionary = b.Abilities.get_skill(id)
	if skill.target != "self":
		cell = b.units[0 if caster >= 5 or id == "heal" else 5].cell
	b.events.clear()
	check(b.use_ability(caster, id, cell), "fixture ability " + id)
	var before: Array[Dictionary] = b.units.duplicate(true)
	var round_before: int = b.round_number
	scene.arena.present(b.events)
	await settle()
	check(b.units == before and b.round_number == round_before, "audio changed combat " + id)
	check(not scene.audio.played.is_empty(), "no audio " + id)
	coverage["%d:%s" % [caster, id]] = scene.audio.played.map(func(p: Dictionary): return p.cue)
	if id in ["double", "unarmed"]:
		var cue := "hammer_hit" if id == "double" else "punch"
		check(count(cue) == 2, "two separate impacts " + id)
		var times: Array = []
		for p in scene.audio.played:
			if p.cue == cue:
				times.append(p.at)
		check(times.size() == 2 and times[1] - times[0] >= .35, "double separation " + id)
	if id == "fushigiri":
		check(count("sword_slash") == 1 and count("hammer_hit") == 0, "Fushigiri uses blade")
		check(count("sacrifice") == 1 and b.units[1].hp == 71, "HP sacrifice feedback")
	if id == "chain":
		check(
			count("chain_charge") == 1 and count("chain_jump") == 3, "one charge, three link snaps"
		)
	if id == "red_laser":
		check(count("laser_emit") == 1 and count("laser_hit") == 1, "laser emission/contact")


func run() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	scene.audio.persist_settings = false
	root.add_child(scene)
	await process_frame
	scene.arena.presentation_finished.disconnect(scene._on_presentation_finished)
	for cue in scene.audio.catalog:
		check(scene.audio._stream(cue) != null, "decode " + cue)
	for caster in 6:
		await ability(caster, "basic")
		for id in Battle.Abilities.loadout(caster):
			await ability(caster, id)
	await ability(6, "basic")
	await ability(6, "red_laser")
	var b := fixture(0)
	b.apply_status(0, "ice_hammer", 2)
	scene.arena.capture_state()
	b.events.clear()
	b.use_ability(0, "basic", b.units[5].cell)
	scene.arena.present(b.events)
	await settle()
	check(count("hammer_hit") == 1 and count("ice_hit") == 1, "enchanted hammer layers")
	# States/expiration/landing use real status events, without changing their definitions.
	for id in Battle.Statuses.DEFINITIONS:
		b = fixture(2)
		b.events.clear()
		b.apply_status(3 if id == "flight" else 0, id, 1)
		scene.arena.present(b.events)
		await settle()
		check(not scene.audio.played.is_empty(), "status " + id)
		scene.audio.played.clear()
		b.events.clear()
		b._tick_statuses(3 if id == "flight" else 0)
		scene.arena.present(b.events)
		await settle()
		check(not scene.audio.played.is_empty(), "expire " + id)
	# Meteor warnings, reaction resource and impact stages.
	b = fixture(0)
	b.events.clear()
	var centers: Array[Vector2i] = [b.units[0].cell]
	b.prepare_meteors(centers, 1, 40)
	scene.arena.present(b.events)
	await settle()
	check(count("warning") == 1, "one warning for marks")
	b.events.clear()
	b.meteor_response(0, "guard")
	scene.arena.present(b.events)
	await settle()
	check(count("guard") == 1 and count("meteor_hit") == 1, "guard and single meteor impact")
	check(count("guard_hit") == 1, "muffled guarded contact")
	check(b.units[0].defensive_reaction == 0 and b.units[0].actions == 1, "RD untouched by audio")
	# Death and short visual removal.
	b = fixture(2)
	b.spawn_minions()
	scene.arena.capture_state()
	b.events.clear()
	b.deal_damage(2, 6, 999, "true")
	scene.arena.present(b.events)
	await settle()
	for i in 20:
		scene.arena._process(.05)
		scene.audio._process(.05)
	check(count("minion_death") == 1 and count("minion_dissolve") == 1, "death and retirement")
	check(not scene.arena.actors.has(6), "no dead minion actor")
	# Phase switching is based on the presented phase event, not final model polling.
	b = fixture(2)
	b.events.clear()
	b.deal_damage(2, 5, 500, "true")
	scene.arena.present(b.events)
	await settle()
	check(scene.audio.phase_target == 1 and count("phase") == 1, "phase presentation switch")
	# Buses and settings remain independent.
	scene.audio.set_mute("Music", true, false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music muted")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "SFX still on")
	scene.audio.set_volume("SFX", .3, false)
	check(is_equal_approx(scene.audio.settings.SFX, .3), "SFX volume")
	scene.audio.set_mute("Music", false, false)
	for i in 40:
		scene.audio.play_cue("body_hit", {"source": i})
	check(scene.audio.voices.size() <= scene.audio.MAX_VOICES, "voice cap")
	scene.audio.play_cue("meteor_hit", {"source": 999})
	check(count("meteor_hit") >= 1, "important voice admitted")
	scene.audio.restart()
	check(
		scene.audio.voices.size() <= 1 and scene.audio.outcome.is_empty(),
		"reset clears voices/outcome"
	)
	check(scene.audio.phase_target == 0 and not scene.audio.stinger.playing, "reset music state")
	# Final hit, crown, title, natural finish and skip.
	scene.arena.presentation_finished.connect(scene._on_presentation_finished)
	b = fixture(2)
	b.units[5].hp = 1
	scene.arena.capture_state()
	b.events.clear()
	b.deal_damage(2, 5, 10, "true")
	scene.arena.present(b.events)
	await settle()
	check(b.outcome == "BOSS DEFEATED" and scene.victory.playing, "victory after last presentation")
	scene.victory._process(1.01)
	check(count("crown") == 1, "crown contact once")
	scene.victory._process(.05)
	check(scene.audio.stinger.playing, "fanfare at title")
	check(scene.victory.title.text == "REI DAS CINZAS DERROTADO", "approved victory title")
	scene.victory.skip()
	check(
		(
			not scene.audio.stinger.playing
			and not scene.audio.music[0].playing
			and not scene.audio.music[1].playing
		),
		"skip stops fanfare and battle layers"
	)
	scene._restart()
	check(not scene.audio.aura.playing and scene.audio.music[0].playing, "restart after victory")
	scene.audio.defeat()
	check(scene.audio.outcome == "defeat" and scene.audio.stinger.playing, "defeat cue")
	var path := "res://docs/audio/coverage_executed.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(coverage, "\t"))
	print("Marco6 audio: %d checks, %d failures" % [checks, failures])
	scene.audio.shutdown()
	await create_timer(.15).timeout
	scene.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
