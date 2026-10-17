extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
const Support = preload("res://scripts/support/spirit_support.gd")
const MinionAI = preload("res://scripts/ai/minion_ai.gd")
var failures := 0
var checks := 0


func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var identities := [
		"grosso", "kodokami", "cassandra", "thomas", "thuxil", "xardorok", "lacaio", "dalamud"
	]
	var total := 0
	for id in identities:
		var base: String = "res://assets/characters/%s/" % id
		var texture: Texture2D = load(base + "atlas.png")
		var image2d := texture.get_image()
		var metadata: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(base + "atlas.json")
		)
		var frames: SpriteFrames = load(base + "animations.tres")
		expect(image2d.detect_alpha() != Image.ALPHA_NONE, id + " possui alfa")
		expect(
			int(metadata.anchor[0]) == 56 and int(metadata.anchor[1]) == 118,
			id + " tem âncora comum"
		)
		expect(image2d.get_pixel(0, 0).a == 0, id + " tem margem transparente")
		var hashes := {}
		for frame in metadata.frames:
			var n: int = frame.frame
			var columns: int = metadata.grid[0]
			var region := image2d.get_region(
				Rect2i((n % columns) * 112, (n / columns) * 128, 112, 128)
			)
			hashes[hash(region.get_data())] = true
			expect(frame.baseline == 118, id + " pés alinhados")
			total += 1
		expect(hashes.size() == metadata.frames.size(), id + " poses distintas")
		for animation in [
			"idle", "walk", "attack", "attack_alt", "cast", "hit", "evade", "death", "special"
		]:
			expect(frames.has_animation(animation), id + " animação " + animation)
		expect(not frames.get_animation_loop("death"), id + " mantém quadro de derrota")
	expect(total == 232, "232 quadros corporais importados")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	expect(scene.arena.sorting.y_sort_enabled, "Oclusão por pés")
	expect(
		scene.arena.environment.walkable_cells.size() == 131,
		"Piso corresponde a 131 células livres"
	)
	for prop in scene.arena.environment.props:
		var local: Vector2 = (prop.position - scene.arena.ORIGIN) / scene.arena.TILE
		var cell := Vector2i(floori(local.x), floori(local.y))
		expect(
			not scene.battle.inside(cell) or cell in Battle.WALLS, "Prop sólido fora dos caminhos"
		)
	expect(
		scene.arena.actors[0].idle_height > scene.arena.actors[1].idle_height,
		"Grosso maior que Kodokami"
	)
	scene.battle.random_outcomes = false
	scene.battle.units[0].cell = Vector2i(11, 4)
	scene.arena.reset_visuals()
	var hp_before: int = scene.battle.units[5].hp
	scene._set_mode("attack")
	scene._on_cell(Vector2i(12, 4))
	var hp_after: int = scene.battle.units[5].hp
	expect(hp_after < hp_before, "Dano lógico aplicado")
	expect(scene.arena.visual_units[5].hp == hp_before, "Barra aguarda impacto")
	expect(scene.busy, "Interface bloqueia sobreposição")
	scene._end_round()
	expect(scene.battle.round_number == 1, "Sem turno inimigo durante animação")
	await create_timer(0.65).timeout
	expect(scene.arena.visual_units[5].hp == hp_after, "Barra atualiza no impacto")
	expect(scene.battle.units[5].hp == hp_after, "Animação não aplica dano novamente")
	scene._restart()
	expect(not scene.busy and scene.arena.timeline.pending.is_empty(), "Reinício cancela agenda")
	expect(
		scene.arena.actors.size() == 6 and scene.arena.effects.active.is_empty(),
		"Reinício remove apresentação anterior"
	)
	var b := Battle.new()
	b.random_outcomes = false
	b.spawn_minions()
	b.phase = "enemies"
	b.units[6].cell = Vector2i(10, 2)
	b.units[0].cell = Vector2i(8, 2)
	b.events.clear()
	MinionAI.act(b, 6, 0)
	expect(
		b.units[6].actions == 0 and b.units[0].hp == 136,
		"Laser consome ação e causa 14 de dano real"
	)
	var laser_found := false
	for event in b.events:
		laser_found = laser_found or event.get("ability", "") == "red_laser"
	expect(laser_found, "IA emite laser vermelho")
	b.units[6].actions = 1
	b.apply_status(6, "silenced", 1)
	b.events.clear()
	MinionAI.act(b, 6, 0)
	for event in b.events:
		expect(event.get("ability", "") != "red_laser", "Silêncio bloqueia laser")
	scene.arena.capture_state()
	Support.grant(scene.battle)
	scene.arena.present(scene.battle.events)
	await create_timer(0.2).timeout
	expect(
		scene.battle.units.size() == 6 and is_instance_valid(scene.arena.spirit),
		"Espírito aparece sem combatente adicional"
	)
	expect(
		scene.arena.spirit.identity == "dalamud" and scene.arena.spirit.floating,
		"Manifestação etérea flutuante"
	)
	scene._restart()
	expect(scene.arena.spirit == null, "Reinício remove espírito")
	scene.queue_free()
	await process_frame
	print("Verificações visuais: %d; falhas: %d" % [checks, failures])
	quit(1 if failures else 0)
