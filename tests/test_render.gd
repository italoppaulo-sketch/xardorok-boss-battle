extends SceneTree
## Executar com janela/driver gráfico. Não é um teste de renderização em --headless.
const Battle = preload("res://scripts/combat/battle.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Este teste requer display e renderização reais.")
		quit(1)
		return
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var count := 0
	for caster in 6:
		for id in (["basic"] if caster in [0, 5] else []) + Battle.Abilities.loadout(caster):
			scene._restart()
			scene.battle.random_outcomes = false
			var cells := [
				Vector2i(9, 4),
				Vector2i(10, 5),
				Vector2i(5, 4),
				Vector2i(8, 3),
				Vector2i(8, 5),
				Vector2i(10, 4)
			]
			for i in 6:
				scene.battle.units[i].cell = cells[i]
			scene.battle.units[0].hp = 80
			scene.battle.active_index = caster
			scene.selected = mini(caster, 4)
			var skill := Battle.Abilities.get_skill(id)
			var cell: Vector2i = (
				cells[caster]
				if skill.target == "self"
				else cells[5 if skill.target != "ally" else 0]
			)
			if caster == 5:
				scene.battle.phase = "enemies"
				if id == "basic":
					cell = cells[0]
			scene.arena.reset_visuals()
			scene._refresh()
			if not scene.battle.use_ability(caster, id, cell):
				failures += 1
				push_error("Falha ao executar: " + id)
			if id == "meteors":
				scene.battle.round_number += 1
				scene.battle._resolve_world()
			scene.arena.present(scene.battle.events)
			scene._refresh()
			await create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			var image2d := root.get_texture().get_image()
			if image2d == null or image2d.is_empty() or image2d.get_width() != 1200:
				failures += 1
				push_error("Frame inválido: " + id)
			count += 1
	print("Cenários renderizados: %d; falhas: %d" % [count, failures])
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
