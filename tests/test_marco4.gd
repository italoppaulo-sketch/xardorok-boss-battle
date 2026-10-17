extends SceneTree
## Contratos de iniciativa, geometria, percepção, fases e reações.
const Battle = preload("res://scripts/combat/battle.gd")
var checks := 0
var failures := 0


func expect(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)


func fresh() -> RefCounted:
	var b := Battle.new()
	b.random_outcomes = false
	return b


func advance(b: RefCounted) -> void:
	# Decisão explícita antes de avançar; não ignora a nova janela de reação.
	for response in 10:
		if not b.meteor_window:
			break
		if b.response_index < 0:
			b.resolve_meteor_window()
		else:
			b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
	b.end_turn()


func _initialize() -> void:
	initiative_checks()
	geometry_checks()
	perception_checks()
	phase_checks()
	reaction_checks()
	print("Marco 4: %d verificações; %d falhas" % [checks, failures])
	quit(1 if failures else 0)


func initiative_checks() -> void:
	var b := fresh()
	expect(b.initiative == [1, 3, 4, 0, 5, 2], "Iniciativa explícita por velocidade decrescente")
	expect(b.active_index == 1, "Kodokami inicia por velocidade 18")
	expect(b.availability(1, "dodge").is_empty(), "Ativo pode usar bônus")
	var hp: int = b.units[0].hp
	var pm: int = b.units[0].mana
	expect(not b.use_ability(0, "skin", b.units[0].cell), "Bônus fora do turno bloqueado")
	expect(not b.move_unit(0, Vector2i(3, 2)), "Movimento fora do turno bloqueado")
	expect(b.units[0].hp == hp and b.units[0].mana == pm, "Falhas preservam recursos")
	b.units[1].cell = Vector2i(11, 4)
	expect(b.use_ability(1, "dodge", b.units[1].cell), "Bônus do ativo executa")
	expect(b.attack(1, 5), "Ação principal independente do bônus")
	expect(not b.attack(1, 5), "Não duplica ação principal")
	expect(not b.use_ability(1, "dodge", b.units[1].cell), "Não duplica bônus")
	b.units[1].cooldowns.fushigiri = 3
	b.apply_status(1, "rooted", 2)
	advance(b)
	expect(b.active_index == 3, "Encerrar avança ao próximo combatente")
	expect(b.units[1].statuses.rooted == 1, "Estado conta fim de turno do portador")
	expect(b.units[1].cooldowns.fushigiri == 3, "Recarga não conta no fim do turno")
	b.units[4].hp = 0
	advance(b)
	expect(b.active_index == 0, "Iniciativa pula unidade derrotada")
	for turn in 12:
		if b.active_index == 1:
			break
		advance(b)
	expect(b.active_index == 1 and b.round_number == 2, "Ordem cíclica avança rodada")
	expect(b.units[1].cooldowns.fushigiri == 2, "Recarga conta início do portador")
	expect(b.units[1].actions == 1 and b.units[1].bonus == 1, "Recursos renovam início do portador")
	expect(b.has_status(1, "rooted"), "Outros turnos não expiram estado do portador")
	advance(b)
	expect(not b.has_status(1, "rooted"), "Segundo fim do portador expira estado")
	b = fresh()
	for step in 6:
		if b.active_index == 5:
			break
		advance(b)
	b.units[0].cell = Vector2i(11, 4)
	b.act_enemy()
	var once_hp: int = b.units[0].hp
	var once_events: int = b.events.size()
	b.act_enemy()
	expect(
		b.units[0].hp == once_hp and b.events.size() == once_events,
		"Turno inimigo não duplica ação/aura"
	)
	b = fresh()
	b.spawn_minions()
	var newborn: int = b.units.size() - 1
	expect(newborn >= 6, "Invocação gera combatentes")
	var acted_early := false
	for turn in 6:
		acted_early = acted_early or b.active_index >= 6
		advance(b)
	expect(not acted_early, "Lacaios aguardam próxima rodada")
	var entered := false
	for turn in 10:
		entered = entered or b.active_index >= 6
		advance(b)
	expect(entered, "Lacaios entram na iniciativa seguinte")


func geometry_checks() -> void:
	var b := fresh()
	var spans := [[3, 11], [1, 13], [0, 14], [0, 14], [0, 14], [0, 14], [0, 14], [1, 13], [3, 11]]
	var floors := 0
	for y in 9:
		for x in 15:
			var expected: bool = x >= spans[y][0] and x <= spans[y][1]
			expect(b.inside(Vector2i(x, y)) == expected, "Piso oval %d,%d" % [x, y])
			floors += int(expected)
	expect(floors == 119, "119 células da plataforma antes das quatro ruínas")
	for cell in [Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 5), Vector2i(7, 6)]:
		expect(cell not in b.WALLS, "Centro sem pilares invisíveis")
	for i in 6:
		for cell in b.reachable(i):
			expect(b.inside(cell) and cell not in b.WALLS, "Navegação coincide com piso")


func perception_checks() -> void:
	var b := fresh()
	b.active_index = 5
	b.units[5].cell = Vector2i(10, 4)
	b.units[1].cell = Vector2i(5, 4)
	expect(b.use_ability(5, "smoke", b.units[5].cell), "Fumaça usa regra real")
	expect(is_equal_approx(float(b.smoke[0].radius), 3.0), "Fumaça tem raio três")
	b.active_index = 1
	expect(not b.can_observe(1, 5), "Chefe oculto para observador exterior")
	expect(not b.player_visible(5), "Ponto de vista do ativo oculta chefe")
	b.units[0].cell = Vector2i(9, 4)
	expect(not b.can_observe(1, 0), "Herói interior oculto para exterior")
	expect(
		b.preview_reachable(1).has(b.units[0].cell), "Prévia não denuncia célula de ocupante oculto"
	)
	expect(not b.reachable(1).has(b.units[0].cell), "Movimento real preserva colisão oculta")
	b.spawn_minions()
	b.units[6].cell = Vector2i(10, 5)
	expect(not b.can_observe(1, 6), "Lacaio interior oculto")
	b.units[1].cell = Vector2i(8, 4)
	expect(b.can_observe(1, 5), "Mesma região permite observação")
	expect(b.can_observe(1, 0), "Entrada revela aliado na mesma região")
	b.units[1].cell = Vector2i(5, 4)
	expect(not b.player_visible(5), "Saída torna chefe oculto novamente")
	b.active_index = 3
	b.units[3].cell = Vector2i(6, 4)
	var before: int = b.units[5].hp
	expect(not b.use_ability(3, "energy_arrow", b.units[5].cell), "Ataque direto rejeita oculto")
	expect(b.use_ability(3, "ice_arrow", b.units[5].cell), "Área pode atingir posição sem visão")
	expect(b.units[5].hp < before, "Ocultação não concede invulnerabilidade")
	expect(not b.player_visible(5), "Área não revela automaticamente vítima")
	b.active_index = 4
	b.units[4].cell = Vector2i(6, 5)
	expect(not b.use_ability(4, "chain", b.units[5].cell), "Raio direcionado respeita ocultação")
	b.active_index = 2
	b.units[2].cell = Vector2i(5, 5)
	expect(b.use_ability(2, "antispell", b.units[5].cell), "Antimagia pode mirar região oculta")
	expect(b.smoke.is_empty() and b.can_observe(2, 5), "Antimagia remove região e restaura visão")
	b = fresh()
	b.active_index = 5
	b.use_ability(5, "smoke", b.units[5].cell)
	b.round_number += 2
	b._resolve_world()
	expect(b.smoke.is_empty(), "Fumaça dissipa naturalmente após duração")


func phase_checks() -> void:
	var b := fresh()
	expect(b.boss_phase == 1, "Chefe inicia primeira fase")
	b.deal_damage(1, 5, 449, "true")
	expect(b.boss_phase == 1 and b.units[5].hp == 451, "451 HP mantém primeira fase")
	b.apply_status(5, "rooted", 2)
	var actions: int = b.units[5].actions
	b.events.clear()
	b.deal_damage(1, 5, 1, "true")
	expect(b.boss_phase == 2 and b.units[5].hp == 450, "450 HP dispara segunda fase")
	expect(
		b.has_status(5, "rooted") and b.units[5].actions == actions,
		"Transição preserva estado e recursos"
	)
	var transitions := 0
	for event in b.events:
		if event.kind == "phase":
			transitions += 1
	b.events.clear()
	b.deal_damage(1, 5, 10, "true")
	for event in b.events:
		if event.kind == "phase":
			transitions += 1
	expect(transitions == 1, "Transição registrada exatamente uma vez")


func reaction_checks() -> void:
	var b := fresh()
	var hp: Array[int] = []
	for i in 5:
		hp.append(b.units[i].hp)
	var boss_actions: int = b.units[5].actions
	advance(b)
	expect(b.reactions_used == 0, "Primeiro herói não dispara reação")
	b.events.clear()
	advance(b)
	expect(b.reactions_used == 1, "Segundo turno de herói dispara preparação")
	expect(b.units[5].actions == boss_actions, "Reação não gasta ação principal do chefe")
	var warnings := 0
	for event in b.events:
		if event.kind == "reaction":
			warnings += 1
	expect(warnings == 1, "Reação registra um aviso")
	# Marco5 substitui preparação vazia por reação tática com janela explícita.
	if b.meteor_window:
		for step in 10:
			if not b.meteor_window:
				break
			if b.response_index < 0:
				b.resolve_meteor_window()
			else:
				b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
	for turn in 12:
		if b.round_number >= 2:
			break
		if b.meteor_window:
			if b.response_index < 0:
				b.resolve_meteor_window()
			else:
				b.meteor_response(b.response_index, "stay", b.units[b.response_index].cell)
			continue
		expect(b.reactions_used <= 2, "Limite configurado de duas reações respeitado")
		advance(b)
	expect(b.round_number == 2 and b.reactions_used == 0, "Nova rodada renova limite de reações")
	b = fresh()
	b.apply_status(5, "frozen", 4)
	advance(b)
	advance(b)
	expect(b.reactions_used == 0, "Congelamento bloqueia reação")
	b = fresh()
	b.apply_status(5, "silenced", 4)
	advance(b)
	advance(b)
	expect(b.reactions_used == 0, "Silêncio bloqueia preparação mágica")
