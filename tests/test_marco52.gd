extends SceneTree
## Isolated fixtures assert rules through production APIs, without replacing combat logic.
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
	for step in 12:
		if not b.meteor_window:
			return
		if b.response_index < 0:
			b.resolve_meteor_window()
		else:
			b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
	expect(not b.meteor_window, "Resposta termina em número finito de decisões")


func threat(b: RefCounted, index: int) -> void:
	var cells: Array[Vector2i] = [b.units[index].cell]
	b.prepare_meteors(cells, 0, 40)


func _initialize() -> void:
	reactions()
	guard_damage()
	multi_and_reset()
	minions()
	minion_ai()
	cursor_checks()
	print("Marco 5.2 regras: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)


func reactions() -> void:
	var b := fresh()
	for index in 5:
		expect(b.units[index].defensive_reaction == 1, "Cada herói inicia com uma RD")
	b.active_index = 0
	b.units[0].cell = Vector2i(6, 4)
	b.units[0].bonus = 0
	b.units[0].mana = 0
	threat(b, 0)
	var destination: Vector2i = b.emergency_destinations(0).keys()[0]
	expect(
		b.can_meteor_response(0, "evade", destination).is_empty(),
		"Sem bônus ou PM a evasão está disponível"
	)
	var serial: int = b.turn_serial
	expect(b.meteor_response(0, "evade", destination), "Evasão atual executa")
	expect(b.units[0].defensive_reaction == 0, "Evasão consome RD")
	expect(b.units[0].actions == 0, "Ação disponível no turno atual é consumida")
	expect(not b.emergency_action_debt.has(0), "Ação consumida agora não gera débito adicional")
	expect(b.units[0].bonus == 0 and b.units[0].mana == 0, "Evasão não cobra bônus ou PM")
	expect(b.turn_serial == serial and b.active_index == 0, "Evasão não concede novo turno")
	close_window(b)
	b._refresh_resources(0, 5)
	expect(b.units[0].actions == 1, "Próxima ação fica normal quando a atual foi sacrificada")
	expect(b.units[0].defensive_reaction == 0, "Refresh individual não renova RD")
	threat(b, 0)
	expect(
		not b.can_meteor_response(0, "guard", b.units[0].cell).is_empty(),
		"Não pode defender após gastar mesma RD"
	)
	expect(b.emergency_destinations(0).is_empty(), "Não pode evadir duas vezes por rodada")
	close_window(b)
	b = fresh()
	b.active_index = 5
	b.units[0].cell = Vector2i(6, 4)
	b.units[0].actions = 1
	b.units[0].bonus = 0
	threat(b, 0)
	destination = b.emergency_destinations(0).keys()[0]
	expect(b.meteor_response(0, "evade", destination), "Evasão fora do turno disponível")
	expect(
		b.units[0].actions == 1 and b.emergency_action_debt.has(0),
		"Ação antiga fora de turno não é consumida; registra débito"
	)
	close_window(b)
	b._refresh_resources(0, 5)
	expect(
		b.units[0].actions == 0 and not b.emergency_action_debt.has(0),
		"Débito compromete exatamente a próxima ação"
	)
	b._refresh_resources(0, 5)
	expect(b.units[0].actions == 1, "Segundo refresh não reaplica penalidade")
	b = fresh()
	b.active_index = 0
	b.units[0].cell = Vector2i(6, 4)
	b.units[0].actions = 0
	threat(b, 0)
	destination = b.emergency_destinations(0).keys()[0]
	expect(b.meteor_response(0, "evade", destination), "Ação já utilizada permite evasão com RD")
	expect(b.emergency_action_debt.has(0), "Evasão após agir gera um débito")
	close_window(b)
	b._refresh_resources(0, 5)
	expect(b.units[0].actions == 0, "Próxima principal indisponível após agir e evadir")
	b._refresh_resources(0, 5)
	expect(b.units[0].actions == 1, "Penalidade aplicada uma vez")


func guard_damage() -> void:
	var full := fresh()
	full.units[0].cell = Vector2i(6, 4)
	var hp: int = full.units[0].hp
	threat(full, 0)
	close_window(full)
	var damage: int = hp - full.units[0].hp
	var b := fresh()
	b.units[0].cell = Vector2i(6, 4)
	b.units[0].bonus = 0
	b.units[0].mana = 0
	var actions: int = b.units[0].actions
	threat(b, 0)
	expect(b.meteor_response(0, "guard", b.units[0].cell), "Defesa funciona sem bônus e sem PM")
	expect(b.units[0].defensive_reaction == 0, "Defesa consome RD")
	expect(b.units[0].bonus == 0 and b.units[0].mana == 0, "Defesa preserva bônus/PM esgotados")
	expect(
		b.units[0].actions == actions and not b.emergency_action_debt.has(0),
		"Defesa preserva principal sem débito"
	)
	close_window(b)
	expect(
		hp - b.units[0].hp == roundi(damage * 0.5),
		"Defesa reduz exatamente metade do dano meteorítico determinístico"
	)
	expect(b.is_burning_cell(b.units[0].cell), "Defesa não impede incêndio secundário no piso")
	b = fresh()
	b.units[0].cell = Vector2i(6, 4)
	b.units[0].defensive_reaction = 0
	threat(b, 0)
	expect(
		not b.can_meteor_response(0, "guard", b.units[0].cell).is_empty(),
		"Sem RD defesa indisponível"
	)
	expect(b.emergency_destinations(0).is_empty(), "Sem RD evasão indisponível")
	hp = b.units[0].hp
	close_window(b)
	expect(hp - b.units[0].hp == damage, "Sem reação recebe dano integral")
	b = fresh()
	b.units[0].cell = Vector2i(6, 4)
	threat(b, 0)
	b.meteor_response(0, "stay", b.units[0].cell)
	expect(b.units[0].defensive_reaction == 1, "Não reagir preserva RD")


func multi_and_reset() -> void:
	var b := fresh()
	b.units[0].cell = Vector2i(6, 4)
	b.units[1].cell = Vector2i(6, 5)
	var cells: Array[Vector2i] = [Vector2i(6, 4)]
	b.prepare_meteors(cells, 1, 40)
	var seen := {}
	for step in 5:
		if not b.meteor_window or b.response_index < 0:
			break
		var hero: int = b.response_index
		expect(not seen.has(hero), "Cada ameaçado responde somente uma vez")
		seen[hero] = true
		b.meteor_response(hero, "guard", b.units[hero].cell)
	close_window(b)
	expect(seen.has(0) and seen.has(1), "Múltiplos heróis respondem independentemente")
	expect(
		b.units[0].defensive_reaction == 0 and b.units[1].defensive_reaction == 0,
		"RD individual consumida"
	)
	b.active_index = b.initiative.back()
	b.turn_cursor = b.initiative.size() - 1
	var previous_round: int = b.round_number
	b.end_turn()
	expect(b.round_number == previous_round + 1, "Fim real da iniciativa avança rodada")
	for hero in 5:
		expect(b.units[hero].defensive_reaction == 1, "Início da rodada renova uma RD")
	var reset := fresh()
	expect(
		reset.emergency_action_debt.is_empty() and not reset.meteor_window,
		"Nova batalha sem débitos ou janela"
	)
	for hero in 5:
		expect(reset.units[hero].defensive_reaction == 1, "Nova batalha restaura RD")


func minions() -> void:
	var b := fresh()
	b.spawn_minions()
	for index in range(6, b.units.size()):
		expect(b.units[index].max_hp == 90 and b.units[index].hp == 90, "HP lacaio aumentado 50%")
		expect(b.units[index].damage == 14, "Dano base lacaio preservado")
	b.spawn_minions()
	b.spawn_minions()
	expect(b.living_minions() == 4, "Limite quatro lacaios vivos")
	var occupied := {}
	for unit in b.units:
		expect(not occupied.has(unit.cell), "Invocação respeita ocupação")
		occupied[unit.cell] = true
	var index := 6
	var freed: Vector2i = b.units[index].cell
	b.deal_damage(0, index, 999, "arcane")
	expect(
		b.units[index].hp == 0 and b.unit_at(freed) == -1,
		"Lacaio morto libera célula imediatamente"
	)
	expect(index not in b.initiative, "Morto removido da iniciativa")
	expect(b.units.size() == 10, "Índices estáveis protegem eventos pendentes")
	var casts: int = b.events.size()
	b.active_index = index
	b.act_enemy()
	expect(b.events.size() == casts, "Morto não age")
	b.active_index = 5
	b.spawn_minions()
	expect(
		b.living_minions() == 4 and b.units.size() == 11,
		"Nova invocação reutiliza capacidade sem reciclar índice"
	)
	b = fresh()
	b.active_index = 5
	b.act_enemy()
	expect(
		b.initial_summon_done and b.living_minions() == 2,
		"Primeira ação principal continua invocação"
	)
	expect(b.units[5].cooldowns.get("summon", 0) == 3, "Recarga configurada três turnos")
	for index2 in range(6, b.units.size()):
		b.deal_damage(0, index2, 999, "arcane")
	for tick in 3:
		b._refresh_resources(5, 4)
	b.enemy_acted_serial = -1
	b.events.clear()
	b.act_enemy()
	var summoned := false
	for event in b.events:
		if event.kind == "cast" and event.get("ability", "") == "summon":
			summoned = true
	expect(summoned and b.living_minions() >= 2, "IA repõe lacaios com recarga disponível")


func minion_ai() -> void:
	var b := fresh()
	b.spawn_minions()
	b.active_index = 6
	b.units[6].cell = Vector2i(12, 4)
	b.units[5].cell = Vector2i(13, 7)
	b.units[0].cell = Vector2i(5, 4)
	b.units[6].move = 3
	var before: Vector2i = b.units[6].cell
	b.events.clear()
	b.MinionAI.act(b, 6, 0)
	expect(b.units[6].cell != before, "Mago fora de alcance se desloca")
	expect(
		b.distance(b.units[6].cell, b.units[0].cell) >= 3,
		"Mago mantém distância em vez de corpo a corpo"
	)
	var moved := false
	var laser := false
	for event in b.events:
		if event.kind == "move" and event.source == 6:
			moved = true
			var prior := before
			for point in event.path:
				expect(b.distance(prior, point) == 1, "Rota animada usa passos adjacentes")
				expect(point not in b.WALLS, "Rota evita ruínas")
				prior = point
		if event.kind == "cast" and event.get("ability", "") == "red_laser":
			laser = true
	expect(moved and laser, "Movimento real permite disparar laser no mesmo turno")
	b = fresh()
	b.spawn_minions()
	b.active_index = 6
	b.units[6].cell = Vector2i(5, 4)
	b.units[0].cell = Vector2i(8, 4)
	b.FireRules.ignite(b, b.units[6].cell, 0)
	b.MinionAI.act(b, 6, 0)
	expect(not b.is_burning_cell(b.units[6].cell), "Mago abandona fogo quando há saída segura")


func cursor_checks() -> void:
	for situation in ["before", "after", "current"]:
		var b := fresh()
		b.spawn_minions()
		b.round_number = 2
		b.initiative = b.Initiative.order(b.units, 2)
		var actor := 3 if situation == "before" else (1 if situation == "after" else 6)
		b.active_index = actor
		b.turn_cursor = b.initiative.find(actor)
		b.reactions_used = 2
		b.deal_damage(0, 6, 999, "arcane")
		b.end_turn()
		expect(
			b.active_index == (4 if situation == "before" else 7),
			"Remover morto %s do cursor não pula próximo combatente" % situation
		)
		expect(
			6 not in b.initiative and b.units.size() == 8,
			"Iniciativa poda índice morto mantendo referências de eventos"
		)
	var b := fresh()
	b.active_index = 5
	b.units[0].cell = Vector2i(6, 4)
	threat(b, 0)
	var destination: Vector2i = b.emergency_destinations(0).keys()[0]
	b.meteor_response(0, "evade", destination)
	close_window(b)
	b.renew_defensive_reactions()
	threat(b, 0)
	destination = b.emergency_destinations(0).keys()[0]
	b.meteor_response(0, "evade", destination)
	close_window(b)
	for step in 2:
		b._refresh_resources(0, 5)
		expect(
			b.units[0].actions == 0,
			"Duas evasões distintas antes do turno comprometem duas ações, sem perdão de dívida"
		)
	b._refresh_resources(0, 5)
	expect(
		b.units[0].actions == 1 and not b.emergency_action_debt.has(0),
		"Débitos separados terminam após cobrança exata"
	)
