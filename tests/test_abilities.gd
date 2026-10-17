extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
const Support = preload("res://scripts/support/spirit_support.gd")
var checks := 0
var failures := 0


func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)
	else:
		print("PASS: ", description)


func fixture() -> RefCounted:
	var b := Battle.new()
	b.random_outcomes = false
	b.active_index = 0
	var cells := [
		Vector2i(9, 4),
		Vector2i(9, 5),
		Vector2i(5, 4),
		Vector2i(8, 3),
		Vector2i(8, 5),
		Vector2i(10, 4)
	]
	for i in 6:
		b.units[i].cell = cells[i]
	return b


func cast(b: RefCounted, index: int, id: String, target: int = -1) -> bool:
	b.active_index = index
	var cell: Vector2i = b.units[index if target < 0 else target].cell
	return b.use_ability(index, id, cell)


func _initialize() -> void:
	_test_grosso()
	_test_kodokami()
	_test_thomas()
	_test_cassandra()
	_test_thuxil()
	_test_boss()
	_test_states_and_rules()
	print("Verificações: %d; falhas: %d" % [checks, failures])
	quit(1 if failures else 0)


func _test_grosso() -> void:
	var b := fixture()
	expect(cast(b, 0, "skin"), "Pele Glacial selecionável")
	expect(b.units[0].bonus == 0 and b.units[0].actions == 1, "Pele usa só bônus")
	expect(
		b.has_status(0, "ice_skin") and b.has_status(0, "defense"), "Pele aplica espinhos e defesa"
	)
	var boss_hp: int = b.units[5].hp
	b.active_index = 5
	expect(b.attack(5, 0), "Chefe pode atingir Grosso com pele")
	expect(b.units[0].hp == 130, "Defesa reduz golpe de 30 para 20")
	expect(b.units[5].hp < boss_hp, "Pele devolve dano de contato")
	b = fixture()
	cast(b, 0, "skin")
	b.apply_status(5, "fire_aura", 3)
	b.apply_status(5, "silenced", 1)
	b.active_index = 0
	b.end_turn()
	expect(b.units[0].hp < 150, "Aura já ativada fere Grosso protegido mesmo sob silêncio")
	b = fixture()
	expect(cast(b, 0, "hammer"), "Martelo Glacial selecionável")
	expect(cast(b, 0, "double", 5), "Ataque Duplo combina com bônus de martelo")
	expect(
		b.units[5].hp == b.units[5].max_hp - 46,
		"Dois golpes aplicam dano físico e gelo com vulnerabilidade"
	)
	expect(b.units[0].actions == 0, "Ataque Duplo consome uma ação")
	b = fixture()
	expect(cast(b, 0, "giant"), "Forma Gigante selecionável")
	expect(b.skill_range(0, "basic") == 2, "Gigante amplia alcance")
	expect(b.has_status(0, "attack"), "Gigante amplia força")
	expect(not b.move_unit(0, Vector2i(3, 1)), "Gigante não atravessa pilar")
	expect(b.move_unit(0, Vector2i(8, 4)), "Gigante mantém movimento com colisão por célula")
	b = fixture()
	cast(b, 0, "hammer")
	b.random_outcomes = true
	b.rng.seed = 7
	var froze := false
	for trial in 40:
		b.units[0].actions = 1
		b.units[5].hp = 520
		b.outcome = ""
		cast(b, 0, "double", 5)
		if b.has_status(5, "frozen"):
			froze = true
	expect(froze, "Martelo pode aplicar congelamento em golpes reais")


func _test_kodokami() -> void:
	var b := fixture()
	b.units[1].cell = Vector2i(10, 5)
	expect(cast(b, 1, "unarmed", 5), "Ataque desarmado duplo executa")
	expect(
		b.units[5].hp == b.units[5].max_hp - 24,
		"Dois golpes desarmados causam 24 após resistência e armadura"
	)
	b = fixture()
	expect(cast(b, 1, "dodge"), "Esquiva ativa usa bônus")
	expect(
		b.has_status(1, "evasion") and b.units[1].evasion == 0.25,
		"Esquiva aumentada soma à natural"
	)
	b = fixture()
	expect(cast(b, 1, "fushigiri", 5), "Fushigiri alcança alvo a dois passos")
	expect(
		b.units[1].hp == 71 and b.units[1].mana == 80, "Fushigiri cobra exatamente 24 HP e 20 PM"
	)
	expect(
		b.units[5].hp == b.units[5].max_hp - 72,
		"Fushigiri aplica 72 após resistência sombria de 20% e armadura"
	)
	b = fixture()
	b.units[1].hp = 24
	expect(not cast(b, 1, "fushigiri", 5), "Fushigiri rejeita HP insuficiente")
	expect(b.units[1].actions == 1 and b.units[1].mana == 100, "Falha não consome recursos")
	b = fixture()
	b.random_outcomes = true
	b.rng.seed = 99
	var misses := 0
	b.apply_status(1, "evasion", 2)
	for trial in 200:
		b.units[1].hp = 95
		if b.deal_damage(5, 1, 1, "physical") == 0:
			misses += 1
	expect(
		misses > 75 and misses < 150, "Esquiva real usa probabilidade aumentada e RNG reproduzível"
	)


func _test_thomas() -> void:
	var b := fixture()
	expect(cast(b, 3, "root_arrow", 5), "Flecha Enraizante executa")
	expect(b.has_status(5, "rooted"), "Flecha aplica enraizamento")
	b.active_index = 5
	expect(not b.move_unit(5, Vector2i(11, 4)), "Alvo enraizado não desloca")
	b = fixture()
	b.active_index = 5
	b.spawn_minions()
	b.active_index = 0
	var before: int = b.units[5].hp
	expect(cast(b, 3, "ice_arrow", 5), "Flecha de Gelo executa")
	expect(b.units[5].hp == before - 34, "Chefe é vulnerável a gelo")
	expect(b.units[6].hp == 22 and b.units[7].hp == 22, "Espinhos atingem dois lacaios em área")
	expect(b.units[0].hp == 150, "Gelo em área não causa fogo amigo")
	b = fixture()
	expect(cast(b, 3, "energy_arrow", 5), "Flecha Energizada executa")
	expect(
		b.units[5].hp == b.units[5].max_hp - 49 and b.units[3].cooldowns.energy_arrow == 2,
		"Flecha aplica dano elevado e recarga"
	)
	b.units[3].actions = 1
	expect(not cast(b, 3, "energy_arrow", 5), "Recarga bloqueia repetição")
	b = fixture()
	b.units[3].cell = Vector2i(2, 1)
	b.active_index = 3
	expect(b.reachable(3).get(Vector2i(4, 1), 999) > 2, "Caminho terrestre contorna pilar")
	expect(cast(b, 3, "flight"), "Botas Mágicas executam")
	expect(b.reachable(3).get(Vector2i(4, 1), 999) == 2, "Voo atravessa pilar pelo caminho curto")
	expect(not b.move_unit(3, Vector2i(3, 1)), "Voo nunca pousa sobre pilar")
	expect(b.move_unit(3, Vector2i(4, 1)), "Voo pousa em célula livre")
	var hp: int = b.units[3].hp
	b.deal_damage(5, 3, 14, "physical")
	expect(b.units[3].hp < hp, "Voo não concede invulnerabilidade física")
	b._tick_statuses(3)
	b._tick_statuses(3)
	expect(not b.has_status(3, "flight"), "Voo expira e personagem retorna ao chão")


func _test_cassandra() -> void:
	var b := fixture()
	b.units[0].hp = 110
	expect(cast(b, 2, "heal", 0), "Cura aceita aliado vivo")
	expect(b.units[0].hp == 150, "Cura respeita HP máximo")
	b = fixture()
	b.units[0].hp = 0
	expect(not cast(b, 2, "heal", 0), "Cura não ressuscita personagem caído")
	b = fixture()
	expect(cast(b, 2, "purple_fire", 5), "Raio de Fogo Roxo executa")
	expect(
		b.units[5].hp == b.units[5].max_hp - 42, "Fogo violeta distingue resistência ao fogo comum"
	)
	b = fixture()
	b.active_index = 5
	expect(cast(b, 5, "smoke"), "Xardorok conjura fumaça")
	b.active_index = 0
	expect(not b.visible(b.units[2].cell, b.units[5].cell), "Fumaça bloqueia visão para dentro")
	expect(not b.visible(b.units[5].cell, b.units[2].cell), "Fumaça bloqueia visão para fora")
	expect(not cast(b, 2, "purple_fire", 5), "Magia com visão não atravessa fumaça")
	expect(cast(b, 2, "antispell", 5), "Antispell funciona de fora da fumaça")
	expect(
		b.smoke.is_empty() and b.visible(b.units[2].cell, b.units[5].cell),
		"Antispell restaura visão real"
	)
	b = fixture()
	b.apply_status(0, "burning", 2)
	b.apply_status(0, "rooted", 1)
	cast(b, 2, "antispell", 0)
	expect(b.units[0].statuses.is_empty(), "Antispell remove estados negativos do aliado")
	b = fixture()
	b.apply_status(5, "defense", 2)
	cast(b, 2, "antispell", 5)
	expect(not b.has_status(5, "defense"), "Antispell remove buff de inimigo")
	b = fixture()
	b.meteors.append({"cell": Vector2i(6, 4), "radius": 1, "due": 2})
	b.active_index = 2
	expect(b.use_ability(2, "antispell", Vector2i(6, 4)), "Antispell pode mirar chão")
	expect(b.meteors.is_empty(), "Antispell neutraliza marca de meteoro")


func _test_thuxil() -> void:
	var b := fixture()
	b.active_index = 5
	b.spawn_minions()
	b.active_index = 0
	expect(cast(b, 4, "illusion"), "Duplicata executa como bônus")
	expect(
		b.units.size() == 8 and b.units[4].actions == 1,
		"Ilusão não cria unidade permanente nem gasta ação"
	)
	expect(cast(b, 4, "chain", 5), "Raio Encadeado combina com duplicata no mesmo turno")
	expect(b.units[6].hp == 0 and b.units[7].hp == 0, "Raio com crítico elimina múltiplos lacaios")
	expect(b.units[5].hp == b.units[5].max_hp - 43, "Ilusão garante crítico no chefe")
	expect(not b.has_status(4, "illusion"), "Ilusão é consumida pelo ataque")
	var links := 0
	for event in b.events:
		if event.kind == "link":
			links += 1
	expect(links == 3, "Raio registra conexões entre três alvos")
	b = fixture()
	expect(cast(b, 4, "silence", 5), "Silêncio selecionável contra Xardorok")
	b.active_index = 5
	b.events.clear()
	b.act_enemy()
	var cast_events: Array[Dictionary] = b.events.duplicate(true)
	b.end_turn()
	var physical := false
	var spell := false
	for event in cast_events:
		if event.kind == "cast" and event.source == 5:
			physical = physical or event.ability == "basic"
			spell = spell or event.ability != "basic"
	expect(physical and not spell, "Xardorok silenciado usa somente ataque físico")
	expect(not b.has_status(5, "silenced"), "Silêncio expira após turno do alvo")


func _test_boss() -> void:
	var b := fixture()
	b.active_index = 5
	expect(cast(b, 5, "summon"), "Invocação selecionável pela IA")
	expect(b.living_minions() == 2, "Invocação cria dois inimigos com HP próprio")
	b.active_index = 0
	b.apply_status(5, "silenced", 2)
	b.events.clear()
	b.active_index = 5
	b.act_enemy()
	var newborn_acted := false
	for event in b.events:
		if event.kind == "cast" and event.source >= 6:
			newborn_acted = true
	expect(not newborn_acted, "Lacaios não agem na rodada de nascimento")
	b.events.clear()
	for step in 20:
		while b.meteor_window:
			if b.response_index < 0:
				b.resolve_meteor_window()
			else:
				b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
		b.end_turn()
		if b.active_index == 6:
			break
	b.events.clear()
	b.act_enemy()
	var acted := false
	for event in b.events:
		if event.kind == "cast" and event.source >= 6:
			acted = true
	expect(acted, "Lacaios movem e atacam no turno seguinte")
	b.spawn_minions()
	b.spawn_minions()
	expect(b.living_minions() == 3, "Invocações respeitam máximo de três vivos")
	b = fixture()
	b.active_index = 5
	expect(b.use_ability(5, "meteors", Vector2i(9, 4)), "Chuva de Meteoros cria marcas")
	expect(
		not b.meteors.is_empty() and b.units[0].hp == 150,
		"Meteoro é telegrafado e não causa dano imediato"
	)
	var first: int = b.response_index
	var hp: int = b.units[first].hp
	while b.meteor_window:
		if b.response_index < 0:
			b.resolve_meteor_window()
		else:
			b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
	expect(b.units[first].hp < hp, "Meteoro fere personagem dentro da área prevista")
	expect(b.meteors.is_empty(), "Marcas são removidas após oportunidade limitada")
	b = fixture()
	b.active_index = 5
	b.apply_status(5, "silenced", 1)
	expect(
		not cast(b, 5, "smoke") and not cast(b, 5, "summon") and not cast(b, 5, "meteors", 0),
		"Silêncio bloqueia todas as magias do chefe"
	)
	b = fixture()
	b.active_index = 5
	b.initial_summon_done = true
	b.units[5].cooldowns.fire_shield = 9
	b.units[5].cooldowns.smoke = 9
	b.units[0].hp = 1
	var adjacent: Dictionary = Battle.BossAI.choose(b)
	b.units[0].cell = Vector2i(1, 0)
	b.units[1].cell = Vector2i(1, 1)
	b.units[2].cell = Vector2i(1, 2)
	b.units[3].cell = Vector2i(1, 3)
	b.units[4].cell = Vector2i(1, 4)
	var distant: Dictionary = Battle.BossAI.choose(b)
	expect(
		adjacent.id == "basic" and distant.id != "basic",
		"IA muda escolha conforme distância e alvos"
	)


func _test_states_and_rules() -> void:
	var b := fixture()
	expect(not b.apply_status(0, "desconhecido", 2), "Estados desconhecidos são rejeitados")
	b.apply_status(0, "frozen", 1)
	expect(
		not cast(b, 0, "double", 5) and not b.move_unit(0, Vector2i(8, 4)),
		"Congelamento bloqueia ação e deslocamento"
	)
	b.active_index = 0
	b.end_turn()
	expect(not b.has_status(0, "frozen"), "Estado de um turno expira corretamente")
	b = fixture()
	b.apply_status(0, "burning", 1)
	b.units[0].cell = Vector2i(1, 0)
	b._tick_statuses(0)
	expect(
		b.units[0].hp == 142 and not b.has_status(0, "burning"),
		"Queimadura aplica dano antes de expirar"
	)
	b = fixture()
	b.units[3].mana = 0
	expect(
		not cast(b, 3, "energy_arrow", 5) and b.units[3].actions == 1,
		"Mana insuficiente não consome ação"
	)
	expect(not cast(b, 0, "purple_fire", 5), "Herói não usa habilidade de outra classe")
	expect(not b.attack(0, 999), "Índice de alvo inválido é rejeitado")
	b = fixture()
	b.units[5].hp = 1
	expect(
		b.attack(0, 5) and b.outcome == "BOSS DEFEATED",
		"Vitória continua funcional com habilidades novas"
	)
	expect(not cast(b, 0, "skin"), "Não há ações após vitória")
	b = fixture()
	for i in 5:
		b.units[i].hp = 0
	b.check_outcome()
	expect(b.outcome == "GRUPO DERROTADO", "Derrota continua funcional")
	b = fixture()
	cast(b, 3, "energy_arrow", 5)
	b.apply_status(5, "frozen", 20)
	b._refresh_resources(3, 5)
	expect(b.units[3].cooldowns.energy_arrow == 1, "Recarga conta uma rodada, sem liberar cedo")
	b._refresh_resources(3, 5)
	b.active_index = 3
	expect(
		b.units[3].cooldowns.energy_arrow == 0 and b.availability(3, "energy_arrow").is_empty(),
		"Recarga libera na rodada prevista"
	)
	for state_id in Battle.Statuses.DEFINITIONS:
		b = fixture()
		b.apply_status(5, "frozen", 20)
		b.apply_status(3, state_id, 2)
		b._tick_statuses(3)
		expect(b.has_status(3, state_id), "Estado dura após primeira fase: " + state_id)
		b._tick_statuses(3)
		expect(not b.has_status(3, state_id), "Estado termina após segunda fase: " + state_id)

	b = fixture()
	Support.grant(b)
	expect(
		Support.IDENTITY.nature == "spirit" and b.units.size() == 6,
		"Dalamud preparado como espírito sem unidade física"
	)
	expect(
		b.has_status(0, "attack") and b.has_status(4, "defense"),
		"Suporte espiritual futuro concede buffs reais pela mesma arquitetura"
	)
