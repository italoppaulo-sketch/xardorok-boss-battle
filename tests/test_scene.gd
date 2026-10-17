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


func settle(scene: Node) -> void:
	while scene.busy:
		await process_frame


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
	await settle(scene)
	scene.hud.end_requested.emit()
	expect(scene.battle.round_number == 2, "Interface encerra rodada")
	scene.hud.restart_requested.emit()
	expect(scene.battle.round_number == 1, "Reiniciar renova rodada")
	expect(scene.battle.units[0].cell == Vector2i(2, 2), "Reiniciar restaura posições")
	expect(scene.arena.battle == scene.battle, "Arena recebe novo modelo")
	for hero_index in 5:
		scene._select(hero_index)
		var expected: Array = scene.battle.Abilities.loadout(hero_index)
		expect(
			scene.hud.skill_ids == expected, "Menu apresenta habilidades da classe %d" % hero_index
		)
		for skill_index in expected.size():
			expect(
				scene.hud.skill_buttons[skill_index].visible,
				"Botão disponível: " + expected[skill_index]
			)
	scene._select(0)
	scene.hud.skill_buttons[0].pressed.emit()
	expect(scene.battle.has_status(0, "ice_skin"), "Botão executa habilidade pessoal real")
	expect(scene.hud.skill_buttons[1].disabled, "Interface bloqueia segundo bônus na mesma rodada")
	scene._restart()
	scene._select(0)
	scene.hud.skill_buttons[3].pressed.emit()
	await create_timer(0.4).timeout
	expect(scene.arena.scales.get(0, 1.0) > 1.4, "Forma Gigante anima aumento de tamanho")
	scene._restart()
	scene.battle.units[0].hp = 50
	scene.battle.units[0].cell = Vector2i(9, 4)
	scene.battle.units[2].cell = Vector2i(5, 4)
	scene._select(2)
	scene.hud.skill_buttons[1].pressed.emit()
	scene.arena.cell_clicked.emit(Vector2i(9, 4))
	expect(
		scene.selected == 2 and scene.battle.units[0].hp == 110,
		"Clique em aliado cura sem trocar de conjurador"
	)
	expect(scene.battle.units[2].actions == 0, "Cura pela interface consome ação")
	scene.battle.apply_status(0, "burning", 2)
	scene.battle.units[0].cooldowns.skin = 3
	scene.battle.smoke.append({"cell": Vector2i(9, 4), "radius": 2.3, "expires": 4})
	scene.battle.meteors.append({"cell": Vector2i(9, 4), "radius": 1, "due": 3})
	scene.battle.spawn_minions()
	scene._restart()
	expect(
		(
			scene.battle.units.size() == 6
			and scene.battle.smoke.is_empty()
			and scene.battle.meteors.is_empty()
		),
		"Reinício limpa lacaios e regiões mágicas"
	)
	expect(
		scene.battle.units[0].statuses.is_empty() and scene.battle.units[0].cooldowns.is_empty(),
		"Reinício limpa estados e recargas"
	)
	expect(
		scene.battle.units[0].hp == 150 and scene.battle.units[2].mana == 100,
		"Reinício restaura HP e mana"
	)
	expect(
		scene.arena.effects.active.is_empty() and scene.arena.routes.is_empty(),
		"Reinício limpa efeitos visuais e rotas"
	)

	for i in 5:
		scene.battle.units[i].hp = 0
	scene.battle.check_outcome()
	scene._refresh()
	expect(scene.hud.message.text.begins_with("GRUPO DERROTADO"), "Interface mostra derrota")
	scene._restart()
	scene.battle.random_outcomes = false
	scene.battle.units[0].cell = Vector2i(11, 4)
	scene.battle.units[5].hp = 1
	scene._set_mode("attack")
	scene._on_cell(Vector2i(12, 4))
	await settle(scene)
	expect(scene.hud.message.text.begins_with("BOSS DEFEATED"), "Interface mostra vitória")

	scene.queue_free()
	await process_frame
	print("Falhas: ", failures)
	quit(1 if failures else 0)
