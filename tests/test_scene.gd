extends SceneTree
var failures := 0


func expect(value: bool, description: String) -> void:
	if value:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	expect(scene.hud.hero_buttons.size() == 5, "Interface cria cinco botões")
	for i in 5:
		scene.hud.hero_buttons[i].pressed.emit()
		expect(scene.selected == i, "Botão seleciona herói %d" % i)
	scene.hud.action_buttons[1].pressed.emit()
	expect(scene.mode == "attack", "Botão de ataque escolhe modo correto")
	scene.hud.action_buttons[0].pressed.emit()
	expect(scene.mode == "move", "Botão de movimento escolhe modo correto")
	scene.hud.hero_buttons[0].pressed.emit()
	scene.arena.cell_clicked.emit(Vector2i(3, 2))
	expect(scene.battle.units[0].cell == Vector2i(3, 2), "Clique na arena move herói")
	scene.hud.end_requested.emit()
	expect(scene.battle.round_number == 2, "Interface encerra rodada")
	scene.hud.restart_requested.emit()
	expect(scene.battle.round_number == 1, "Reiniciar renova rodada")
	expect(scene.battle.units[0].cell == Vector2i(2, 2), "Reiniciar restaura posições")
	expect(scene.arena.battle == scene.battle, "Arena recebe novo modelo")
	scene.queue_free()
	await process_frame
	print("Falhas: ", failures)
	quit(1 if failures else 0)
