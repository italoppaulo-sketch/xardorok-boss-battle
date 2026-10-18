extends SceneTree
var scene: Node
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	root.push_input(event)
	await process_frame


func run() -> void:
	root.size = Vector2i(1200, 700)
	scene = load("res://scenes/main.tscn").instantiate()
	scene.audio.persist_settings = false
	root.add_child(scene)
	await process_frame
	expect(not scene.audio_panel.panel.visible, "settings initially closed")
	await key(KEY_F10)
	expect(scene.audio_panel.panel.visible, "F10 opens settings")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/audio/controles_marco6.png")
	for bus in scene.audio.settings:
		expect(AudioServer.get_bus_index(bus) >= 0, "bus " + bus)
		scene.audio_panel.sliders[bus].value = 42
		expect(is_equal_approx(scene.audio.settings[bus], .42), "slider " + bus)
	scene.audio_panel.mutes.Music.button_pressed = true
	expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "UI mutes music")
	expect(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "UI preserves effects")
	await key(KEY_M)
	expect(AudioServer.is_bus_mute(0), "M mutes master")
	await key(KEY_M)
	expect(not AudioServer.is_bus_mute(0), "M restores master")
	scene._restart()
	expect(scene.audio.muted.Music, "restart preserves music mute")
	expect(is_equal_approx(scene.audio.settings.SFX, .42), "restart preserves volume")
	await key(KEY_F10)
	expect(not scene.audio_panel.panel.visible, "F10 closes settings")
	var before: Array[Dictionary] = scene.battle.units.duplicate(true)
	scene._execute("fushigiri", Vector2i(12, 4))
	expect(scene.battle.units == before, "invalid action changes no units")
	expect(
		scene.audio.played.any(func(e: Dictionary): return e.cue == "ui_invalid"),
		"invalid action feedback"
	)
	print("Marco6 audio UI: %d checks, %d failures" % [checks, failures])
	scene.audio.shutdown()
	await create_timer(.15).timeout
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
