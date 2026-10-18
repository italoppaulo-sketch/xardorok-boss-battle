extends SceneTree
## Contratos reais do Marco 5: sem cálculos de dano na apresentação.
const Battle = preload("res://scripts/combat/battle.gd")
var checks := 0
var failures := 0


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func fresh() -> RefCounted:
	var b := Battle.new()
	b.random_outcomes = false
	return b


func close_window(b: RefCounted) -> void:
	for step in 10:
		if not b.meteor_window:
			return
		if b.response_index < 0:
			b.resolve_meteor_window()
		else:
			b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
	expect(not b.meteor_window, "Janela de meteoro tem resolução finita")


func meteor_fixture() -> RefCounted:
	var b := fresh()
	b.active_index = 5
	b.units[0].cell = Vector2i(8, 4)
	b.units[1].cell = Vector2i(8, 5)
	b.use_ability(5, "meteors", Vector2i(8, 4))
	return b


func _initialize() -> void:
	opening_checks()
	shield_checks()
	aura_checks()
	meteor_checks()
	floor_checks()
	edge_checks()
	path_fire_checks()
	print("Marco 5 funcional: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)


func opening_checks() -> void:
	var b := fresh()
	expect(b.units[5].hp == 900, "Pressão não depende de aumentar HP")
	expect(not b.initial_summon_done, "Abertura inicia sem invocação executada")
	expect(not b.has_status(5, "fire_aura"), "Aura inicia desativada")
	b.active_index = 5
	b.events.clear()
	b.act_enemy()
	var first_main := ""
	for event in b.events:
		if event.kind == "cast" and event.source == 5 and event.ability != "fire_aura":
			first_main = event.ability
			break
	expect(first_main == "summon", "Primeira ação principal invoca lacaios")
	expect(b.initial_summon_done and b.living_minions() == 2, "Invocação inicial cria dois magos")
	var occupied := {}
	for unit in b.units:
		expect(not occupied.has(unit.cell), "Invocação sem ocupação sobreposta")
		occupied[unit.cell] = true
	b = fresh()
	b.active_index = 5
	b.apply_status(5, "silenced", 1)
	b.act_enemy()
	expect(
		not b.initial_summon_done and b.living_minions() == 0,
		"Silêncio adia invocação legitimamente"
	)
	b._tick_statuses(5)
	b.enemy_acted_serial = -1
	b._refresh_resources(5, 4)
	b.act_enemy()
	expect(
		b.initial_summon_done and b.living_minions() == 2,
		"IA retoma invocação na oportunidade válida"
	)


func shield_checks() -> void:
	var baseline := fresh()
	var base_damage: int = baseline.deal_damage(1, 5, 100, "physical")
	var b := fresh()
	b.active_index = 5
	expect(b.use_ability(5, "fire_shield", b.units[5].cell), "Escudo é habilidade real")
	expect(
		b.units[5].actions == 0 and b.has_status(5, "fire_shield"),
		"Escudo consome ação e aplica estado"
	)
	var reduced: int = b.deal_damage(1, 5, 100, "physical")
	expect(reduced > 0 and reduced < base_damage, "Escudo reduz dano sem invulnerabilidade")
	expect(absi(reduced - roundi(base_damage * 0.6)) <= 1, "Redução de quarenta por cento")
	b.units[5].actions = 1
	expect(not b.use_ability(5, "fire_shield", b.units[5].cell), "Não acumula escudos")
	b.units[0].cell = b.units[5].cell + Vector2i.LEFT
	var hp: int = b.units[0].hp
	b.deal_damage(0, 5, 20, "physical", false, true)
	expect(b.units[0].hp < hp, "Contato efetivo recebe retaliação")
	hp = b.units[3].hp
	b.deal_damage(3, 5, 20, "arcane")
	expect(b.units[3].hp == hp, "Ataque à distância não recebe retaliação")
	b._tick_statuses(5)
	expect(b.has_status(5, "fire_shield"), "Escudo persiste após primeiro turno próprio")
	b._tick_statuses(5)
	expect(not b.has_status(5, "fire_shield"), "Escudo expira após segundo turno próprio")
	expect(b.units[5].cooldowns.get("fire_shield", 0) == 3, "Recarga três começa após expiração")
	for step in 3:
		b._refresh_resources(5, 4)
		expect(b.units[5].cooldowns.fire_shield == 2 - step, "Recarga conta turnos próprios")
	b = fresh()
	b.active_index = 5
	b.use_ability(5, "fire_shield", b.units[5].cell)
	b.active_index = 2
	b.units[2].cell = Vector2i(8, 4)
	expect(b.use_ability(2, "antispell", b.units[5].cell), "Antimagia mira escudo compatível")
	expect(not b.has_status(5, "fire_shield"), "Antimagia remove escudo")
	expect(b.units[5].cooldowns.get("fire_shield", 0) == 3, "Dissipação também inicia recarga")


func aura_checks() -> void:
	var b := fresh()
	b.active_index = 5
	expect(b.use_ability(5, "fire_aura", b.units[5].cell), "Aura ativável")
	expect(
		b.units[5].bonus == 0 and b.units[5].actions == 1, "Aura custa bônus independente da ação"
	)
	b.units[0].cell = Vector2i(11, 4)
	b.active_index = 0
	var hp: int = b.units[0].hp
	b.move_unit(0, Vector2i(12, 3))
	expect(b.units[0].hp == hp, "Aproximação não duplica dano de aura")
	b.units[0].cell = Vector2i(11, 4)
	b.events.clear()
	b.end_turn()
	var ticks := 0
	for event in b.events:
		if event.kind == "damage" and event.get("cause", "") == "aura" and event.target == 0:
			ticks += 1
	expect(ticks == 1 and b.units[0].hp < hp, "Aura causa um único tick no fim do herói adjacente")
	b.apply_status(5, "silenced", 2)
	b.active_index = 0
	b.units[0].cell = Vector2i(11, 4)
	hp = b.units[0].hp
	b.end_turn()
	expect(b.units[0].hp < hp, "Aura já ativa continua funcionando sob silêncio")
	for step in 3:
		b._tick_statuses(5)
	expect(not b.has_status(5, "fire_aura"), "Aura expira por turnos próprios")


func meteor_checks() -> void:
	var b := meteor_fixture()
	expect(b.meteor_window and not b.meteors.is_empty(), "Conjuração abre janela por evento")
	expect(b.units[0].hp == b.units[0].max_hp, "Aviso antecede dano")
	var first: int = b.response_index
	var actions: int = b.units[first].actions
	var bonus: int = b.units[first].bonus
	var destinations: Dictionary = b.emergency_destinations(first)
	expect(not destinations.is_empty(), "Existe destino válido para evasão")
	if not destinations.is_empty():
		var dest: Vector2i = destinations.keys()[0]
		expect(b.meteor_response(first, "evade", dest), "Evasão emerge pela API real")
		expect(
			b.units[first].actions == actions and b.emergency_action_debt.has(first),
			"Evasão fora do turno compromete a próxima ação"
		)
		expect(b.units[first].bonus == bonus, "Evasão não renova nem consome bônus")
		expect(b.units[first].cell == dest, "Evasão move para célula escolhida")
		for mark in b.meteors:
			expect(
				b.distance(dest, mark.cell) > mark.radius, "Destino sai de todas as áreas ameaçadas"
			)
	close_window(b)
	expect(not b.meteor_window and b.meteors.is_empty(), "Impacto fecha janela sem esperar rodada")
	b = meteor_fixture()
	first = b.response_index
	b.units[first].actions = 0
	expect(
		not b.emergency_destinations(first).is_empty(),
		"Reação Defensiva permite evasão com ação já utilizada"
	)
	b.apply_status(first, "rooted", 1)
	b.units[first].actions = 1
	expect(b.emergency_destinations(first).is_empty(), "Enraizamento impede evasão")
	b.units[first].statuses.clear()
	b.apply_status(first, "frozen", 1)
	expect(b.emergency_destinations(first).is_empty(), "Congelamento impede evasão")
	close_window(b)
	var unguarded := meteor_fixture()
	first = unguarded.response_index
	var before: int = unguarded.units[first].hp
	close_window(unguarded)
	var full_damage: int = before - unguarded.units[first].hp
	b = meteor_fixture()
	first = b.response_index
	before = b.units[first].hp
	var pm: int = b.units[first].mana
	actions = b.units[first].actions
	expect(
		b.meteor_response(first, "guard", b.units[first].cell), "Defesa disponível resolve reação"
	)
	expect(
		(
			b.units[first].mana == pm
			and b.units[first].bonus == bonus
			and b.units[first].defensive_reaction == 0
		),
		"Defesa custa somente Reação Defensiva"
	)
	expect(b.units[first].actions == actions, "Defesa preserva ação sem conceder nova")
	close_window(b)
	expect(before - b.units[first].hp < full_damage, "Defesa reduz dano de impacto")
	before = b.units[first].hp
	b.resolve_meteor_window()
	expect(b.units[first].hp == before, "Resolver novamente não duplica impacto")
	b = meteor_fixture()
	b.smoke.append({"cell": Vector2i(8, 4), "radius": 3, "expires": 5})
	close_window(b)
	expect(
		b.meteors.is_empty() and b.units[0].hp < b.units[0].max_hp,
		"Impacto em fumaça permanece válido"
	)
	b = meteor_fixture()
	b.units[5].hp = 450
	b._update_boss_phase()
	close_window(b)
	expect(
		b.boss_phase == 2 and b.meteors.is_empty(),
		"Mudança de fase não duplica nem abandona meteoro"
	)
	b = meteor_fixture()
	b.units[5].hp = 0
	b.check_outcome()
	close_window(b)
	expect(not b.meteor_window, "Morte do chefe não deixa janela bloqueada")


func floor_checks() -> void:
	var b := meteor_fixture()
	close_window(b)
	expect(not b.fire_zones.is_empty(), "Meteoro incendeia piso anunciado")
	var burned: Vector2i = b.fire_zones[0].cell
	expect(b.inside(burned) and burned not in b.WALLS, "Incêndio apenas em piso jogável")
	b.active_index = 0
	b.units[0].cell = burned
	b.events.clear()
	var hp: int = b.units[0].hp
	b.end_turn()
	expect(b.units[0].hp < hp, "Permanência no fogo tem consequência")
	for step in 5:
		b.round_number += 1
		b._resolve_world()
	expect(b.fire_zones.is_empty(), "Incêndios expiram sem bloquear caminhos permanentemente")


func edge_checks() -> void:
	var b := meteor_fixture()
	var first: int = b.response_index
	var serial: int = b.turn_serial
	var actor: int = b.active_index
	var resources: int = b.units[first].actions
	b.end_turn()
	expect(
		b.turn_serial == serial and b.active_index == actor, "Janela bloqueia avanço de iniciativa"
	)
	expect(b.units[first].actions == resources, "Janela não renova recursos")
	expect(
		not b.move_unit(actor, b.units[actor].cell + Vector2i.LEFT),
		"Movimento comum bloqueado durante resposta"
	)
	b.units[actor].actions = 1
	expect(
		not b.use_ability(actor, "basic", b.units[0].cell), "Ação normal bloqueada durante resposta"
	)
	var event_count: int = b.events.size()
	b.act_enemy()
	expect(b.events.size() == event_count, "IA aguarda resposta sem executar turno adicional")
	b.apply_status(first, "frozen", 1)
	expect(
		not b.can_meteor_response(first, "guard", b.units[first].cell).is_empty(),
		"Congelado não utiliza defesa especial"
	)
	close_window(b)
	b = meteor_fixture()
	first = b.response_index
	var destinations: Dictionary = b.emergency_destinations(first)
	if not destinations.is_empty():
		b.meteor_response(first, "evade", destinations.keys()[0])
		close_window(b)
		b._refresh_resources(first, 5)
		expect(b.units[first].actions == 0, "Evasão fora do turno reserva ação do próximo turno")
		b._refresh_resources(first, 5)
		expect(b.units[first].actions == 1, "Débito de evasão não persiste por dois turnos")
	b = fresh()
	b.active_index = 0
	b.units[0].cell = Vector2i(5, 4)
	b.FireRules.ignite(b, Vector2i(6, 4), 0)
	var hp: int = b.units[0].hp
	expect(b.move_unit(0, Vector2i(6, 4)), "Entrada em piso incendiado mantém movimento válido")
	expect(b.units[0].hp == hp - 8, "Entrada cobra oito de fogo")
	b.move_unit(0, Vector2i(5, 4))
	b.move_unit(0, Vector2i(6, 4))
	expect(b.units[0].hp == hp - 8, "Reentrada no mesmo serial não duplica fogo")
	b.end_turn()
	expect(b.units[0].hp == hp - 8, "Entrada e permanência no mesmo turno contam uma vez")
	b = fresh()
	var centers: Array[Vector2i] = [Vector2i(3, 1)]
	b.prepare_meteors(centers, 1, 40)
	close_window(b)
	for zone in b.fire_zones:
		expect(
			b.inside(zone.cell) and zone.cell not in b.WALLS,
			"Meteoro parcialmente bloqueado respeita piso real"
		)
	b = fresh()
	b.round_number = 7
	b.active_index = 2
	b.turn_cursor = b.initiative.size() - 1
	centers = [b.units[2].cell]
	b.prepare_meteors(centers, 0, 40)
	close_window(b)
	expect(
		b.round_number == 7 and b.meteors.is_empty(),
		"Impacto no fim da rodada não espera próxima rodada"
	)
	b.end_turn()
	expect(
		b.round_number == 8 and not b.meteor_window,
		"Iniciativa retoma após impacto no fim da rodada"
	)
	b = meteor_fixture()
	var queue_size: int = b.response_queue.size() + 1
	expect(queue_size >= 2, "Múltiplos ameaçados recebem oportunidades individuais")
	b.units[5].hp = 0
	b.check_outcome()
	expect(
		not b.meteor_window and b.meteors.is_empty(), "Morte cancela marcas e janela imediatamente"
	)


func path_fire_checks() -> void:
	var b := fresh()
	b.spawn_minions()
	b.active_index = 6
	b.units[6].cell = Vector2i(5, 4)
	b.units[6].move = 5
	b.FireRules.ignite(b, Vector2i(6, 4), 0)
	var direct: Array[Vector2i] = b.Navigation.path(b, 6, Vector2i(7, 4))
	var safe: Array[Vector2i] = b.Navigation.safe_path(b, 6, Vector2i(7, 4))
	expect(Vector2i(6, 4) in direct, "Rota comum mantém menor número de passos")
	expect(
		not safe.is_empty() and Vector2i(6, 4) not in safe,
		"IA encontra desvio quando fogo tem alternativa"
	)
	var hp: int = b.units[6].hp
	expect(b.move_unit(6, Vector2i(7, 4), true), "IA executa rota segura válida")
	expect(b.units[6].hp == hp, "Desvio seguro evita dano ambiental")
	expect(
		b.units[6].move == 5 - safe.size(), "Desvio cobra passos reais sem tarifa fictícia de risco"
	)

	b = fresh()
	b.spawn_minions()
	b.active_index = 6
	b.units[6].cell = Vector2i(5, 4)
	b.units[0].cell = Vector2i(8, 4)
	b.FireRules.ignite(b, Vector2i(5, 4), 0)
	hp = b.units[6].hp
	b.MinionAI.act(b, 6, 0)
	expect(not b.is_burning_cell(b.units[6].cell), "Acólito abandona piso em fogo quando há saída")
	expect(b.units[6].hp == hp, "Saída segura não inventa dano pelo piso anterior")
