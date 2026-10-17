extends SceneTree
## Cliques reais no HUD contextual e destino da evasão.
var scene: Node
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func settle() -> void:
	for frame in 1500:
		await process_frame
		if not scene.busy:
			return
	expect(false, "Apresentação contextual encerra")


func click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()


func run() -> void:
	scene = load("res://scenes/main_original.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var b: RefCounted = scene.battle
	b.random_outcomes = false
	b.units[0].cell = Vector2i(8, 4)
	b.units[1].cell = Vector2i(8, 5)
	b.active_index = 5
	scene.arena.reset_visuals()
	b.events.clear()
	expect(b.use_ability(5, "meteors", b.units[0].cell), "Conjuração real antecede HUD")
	b.active_index = 1
	scene.arena.present(b.events)
	await settle()
	expect(b.meteor_window and scene.hud.emergency_root.visible, "HUD contextual visível")
	var first: int = b.response_index
	var actions: int = b.units[first].actions
	var destinations: Dictionary = b.emergency_destinations(first)
	expect(not destinations.is_empty(), "Destino de evasão disponível")
	await click(scene.hud.emergency_evade.get_global_rect().get_center())
	expect(scene.mode == "meteor_evade", "Clique Evasão seleciona modo contextual")
	if not destinations.is_empty():
		var dest: Vector2i = destinations.keys()[0]
		await click(scene.arena.center(dest))
		expect(b.units[first].cell == dest, "Clique na arena executa evasão")
		expect(b.units[first].actions == actions - 1, "HUD cobra principal da evasão")
	if b.meteor_window and b.response_index >= 0:
		var guarded: int = b.response_index
		var pm: int = b.units[guarded].mana
		await click(scene.hud.emergency_guard.get_global_rect().get_center())
		expect(b.units[guarded].mana == pm - 8, "Botão Defender cobra PM")
		expect(b.units[guarded].bonus == 0, "Botão Defender cobra bônus")
	for response in 8:
		if not b.meteor_window:
			break
		scene._meteor_choice("stay")
		await settle()
	expect(not b.meteor_window, "Respostas encerram janela via interface")
	expect(not scene.hud.emergency_root.visible, "HUD contextual some após impacto")
	scene._restart()
	expect(
		scene.battle.fire_zones.is_empty() and not scene.battle.meteor_window,
		"Reinício limpa reação e incêndios"
	)
	print("Marco5 HUD meteoros: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)
