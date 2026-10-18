extends SceneTree
var failures := 0
var checks := 0
var tested_scene: Node


func expect(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	await process_frame
	while tested_scene.busy or tested_scene.battle.active_index >= 5:
		await process_frame


func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()


func key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()


func run() -> void:
	root.size = Vector2i(1200, 700)
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	tested_scene = scene
	root.add_child(scene)
	await process_frame
	expect(scene.selected == 1, "HUD inicia no combatente ativo")
	await click(scene.hud.hero_buttons[2].get_global_rect().get_center())
	expect(scene.selected == 2, "Clique permite consultar Cassandra")
	expect(scene.hud.skill_buttons[1].disabled, "Cura bloqueada fora do turno")
	await key(KEY_2)
	expect(scene.selected == 1, "Atalho 2 seleciona ativo Kodokami")
	await click(scene.hud.skill_buttons[1].get_global_rect().get_center())
	expect(scene.battle.has_status(1, "evasion"), "Mouse usa bônus de Esquiva real")
	expect(
		scene.battle.units[1].bonus == 0 and scene.battle.units[1].actions == 1,
		"Bônus não consome principal"
	)
	var initial: Vector2i = scene.battle.units[1].cell
	await key(KEY_ESCAPE)
	await click(scene.arena.center(initial + Vector2i.RIGHT))
	expect(scene.battle.units[1].cell == initial + Vector2i.RIGHT, "Mouse move ativo pela arena")
	await key(KEY_SPACE)
	expect(scene.battle.active_index == 3, "Espaço encerra turno e seleciona Thomas")
	await click(scene.hud.skill_buttons[3].get_global_rect().get_center())
	expect(scene.battle.has_status(3, "flight"), "Mouse ativa Botas Mágicas")
	await key(KEY_R)
	expect(
		scene.battle.round_number == 1 and scene.battle.active_index == 1, "R reinicia iniciativa"
	)
	expect(not scene.battle.has_status(3, "flight"), "Reinício remove voo")
	await click(scene.hud.log_button.get_global_rect().get_center())
	expect(scene.hud.log_panel.visible, "Registro abre por clique")
	await click(scene.hud.log_button.get_global_rect().get_center())
	expect(not scene.hud.log_panel.visible, "Registro pode recolher")
	for button in scene.hud.hero_buttons + scene.hud.action_buttons + scene.hud.skill_buttons:
		var rect: Rect2 = button.get_global_rect()
		expect(Rect2(0, 0, 1200, 700).encloses(rect), "Botão cabe em 1200×700")
	for button in scene.hud.skill_buttons:
		if button.visible:
			expect(button.get_node("Glyph").texture != null, "Habilidade tem ícone conectado")
	expect(scene.hud.initiative_buttons.size() == 6, "Seis retratos de iniciativa")
	scene.queue_free()
	await process_frame
	print("Entradas reais: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)
