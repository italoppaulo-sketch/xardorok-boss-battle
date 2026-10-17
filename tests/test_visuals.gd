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
	var icon_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/ui/ability_icons/manifest.json")
	)
	var icon_hashes := {}
	for icon_id in icon_manifest.icons:
		var texture: Texture2D = load(
			"res://assets/ui/ability_icons/" + icon_manifest.icons[icon_id].file
		)
		var icon: Image = texture.get_image()
		expect(icon.get_size() == Vector2i(64, 64), "Ícone 64×64: " + icon_id)
		expect(icon.detect_alpha() != Image.ALPHA_NONE, "Ícone com alfa: " + icon_id)
		icon_hashes[hash(icon.get_data())] = true
	expect(icon_hashes.size() == 37, "37 ícones distintos importados incluindo escudo/aura")
	for skill_id in Battle.Abilities.DATA:
		expect(
			icon_manifest.icons.has("basic_0" if skill_id == "basic" else skill_id),
			"Catálogo tem ícone: " + skill_id
		)
	var boss_frames: SpriteFrames = load("res://assets/characters/xardorok_marco4/animations.tres")
	for animation in ["idle", "walk", "attack", "cast", "hit", "death", "special"]:
		expect(boss_frames.has_animation(animation), "Xardorok Marco4 animação " + animation)
	var scene: Node = load("res://scenes/main_original.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	expect(scene.arena.sorting.y_sort_enabled, "Oclusão por pés")
	expect(
		scene.arena.environment.walkable_cells.size() == 115,
		"Piso corresponde a 115 células livres"
	)
	for prop in scene.arena.environment.props:
		if str(prop.name).begins_with("IceFissure"):
			continue  # Decoração plana, não obstáculo.
		var local: Vector2 = (prop.position - scene.arena.ORIGIN) / scene.arena.TILE
		var cell := Vector2i(floori(local.x), floori(local.y))
		expect(
			not scene.battle.inside(cell) or cell in Battle.WALLS, "Prop sólido fora dos caminhos"
		)
	expect(
		scene.arena.actors[0].idle_height > scene.arena.actors[1].idle_height,
		"Grosso maior que Kodokami"
	)
	var boss_actor: Node2D = scene.arena.actors[5]
	var boss_texture: Texture2D = boss_actor.sprite.sprite_frames.get_frame_texture("idle", 0)
	var boss_image := boss_texture.get_image()
	var crown_pixel := Vector2i.ZERO
	var found_crown := false
	for y in 50:
		for x in boss_image.get_width():
			if boss_image.get_pixel(x, y).a > 0.5:
				crown_pixel = Vector2i(x, y)
				found_crown = true
				break
		if found_crown:
			break
	var crown_local := Vector2(crown_pixel) + Vector2(0.5, 0.5)
	if boss_actor.sprite.flip_h:
		crown_local.x = boss_texture.get_width() - crown_local.x
	crown_local -= boss_texture.get_size() * 0.5
	crown_local += boss_actor.sprite.offset
	var crown_point: Vector2 = scene.arena.to_local(boss_actor.sprite.to_global(crown_local))
	expect(
		found_crown and scene.arena.pointer_cell(crown_point) == scene.battle.units[5].cell,
		"Clique na coroa seleciona célula lógica do chefe"
	)
	scene.battle.random_outcomes = false
	scene.battle.active_index = 0
	scene._select(0)
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
	b.active_index = 6
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
	scene.battle.active_index = 1
	scene.battle.units[1].cell = Vector2i(5, 4)
	scene.battle.units[5].cell = Vector2i(10, 4)
	scene.battle.units[0].cell = Vector2i(9, 4)
	scene.battle.spawn_minions()
	scene.battle.units[6].cell = Vector2i(10, 5)
	scene.battle.smoke.append({"cell": Vector2i(10, 4), "radius": 3.0, "expires": 3})
	scene.arena.reset_visuals()
	scene._select(1)
	await process_frame
	await process_frame
	for hidden in [0, 5, 6]:
		expect(not scene.arena.actors[hidden].visible, "Fumaça oculta sprite %d" % hidden)
		expect(
			not scene.arena.visible_to_player(hidden), "Sobreposição omite nome/HP de %d" % hidden
		)
	scene.hud.inspect_target(scene.battle, Vector2i(10, 4))
	expect(scene.hud.target_info.text.is_empty(), "Inspeção não revela chefe oculto")
	scene.hud.inspect_target(scene.battle, Vector2i(12, 4))
	expect(
		scene.hud.target_info.text.begins_with("Última posição"),
		"HUD distingue memória de alvo visível"
	)
	expect(
		not "900" in scene.hud.target_info.text and not "Xardorok" in scene.hud.target_info.text,
		"Memória não revela HP ou identidade atual"
	)
	scene.battle.units[5].cell = Vector2i(11, 4)
	scene.hud.inspect_target(scene.battle, Vector2i(12, 4))
	expect(
		scene.hud.target_info.text.begins_with("Última posição"),
		"Memória não acompanha movimento oculto"
	)
	scene.battle.units[5].cell = Vector2i(10, 4)
	expect(not scene.hud.boss_hp.visible, "HUD remove HP de chefe oculto")
	expect(
		scene.hud.hero_buttons[0].get_node("Portrait").texture == null,
		"Retrato de herói oculto removido"
	)
	scene._select(0)
	expect(
		(
			scene.selected != 0
			or (not scene.hud.ability_root.visible and not scene.hud.hero_hp.visible)
		),
		"Inspeção oculta não vaza recursos"
	)
	scene.battle.smoke.clear()
	scene.arena.reset_visuals()
	scene._select(1)
	await process_frame
	expect(
		scene.arena.actors[5].visible and scene.hud.boss_hp.visible,
		"Dissipação restaura sprite e HP do chefe"
	)
	scene._restart()
	scene._restart()
	scene.battle.active_index = 5
	scene.battle.units[1].cell = Vector2i(5, 4)
	scene.battle.units[5].cell = Vector2i(10, 4)
	scene.arena.reset_visuals()
	scene.arena.capture_state()
	scene.battle.events.clear()
	expect(scene.battle.use_ability(5, "smoke", Vector2i(10, 4)), "Fumaça de integração executa")
	scene.arena.present(scene.battle.events)
	expect(
		scene.busy and not scene.hud.boss_hp.visible, "HUD retira HP oculto já durante apresentação"
	)
	scene._restart()
	scene.queue_free()
	await process_frame
	print("Verificações visuais: %d; falhas: %d" % [checks, failures])
	quit(1 if failures else 0)
