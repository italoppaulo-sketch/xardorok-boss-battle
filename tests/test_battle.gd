extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
var failures := 0
var checks := 0


func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)


func _initialize() -> void:
	var battle := Battle.new()
	battle.random_outcomes = false
	expect(battle.units.size() == 6, "Cinco heróis e um chefe")
	expect(battle.units[5].hp == 900, "Chefe começa com 900 HP")
	battle.active_index = 0  # Fixture de movimento isolada; iniciativa testada separadamente.
	expect(not battle.move_unit(0, Vector2i(-1, 2)), "Limites da arena")
	expect(not battle.move_unit(0, battle.units[1].cell), "Ocupação bloqueia movimento")
	expect(not battle.move_unit(0, Vector2i(3, 1)), "Ruína bloqueia movimento")
	expect(battle.move_unit(0, Vector2i(4, 2)), "Caminho válido")
	expect(battle.units[0].move == 3, "Movimento desconta custo do caminho")
	expect(not battle.move_unit(0, Vector2i(10, 2)), "Orçamento de movimento")
	expect(not battle.attack(0, 5), "Ataque fora de alcance")
	expect(not battle.attack(0, 1), "Sem fogo amigo")
	expect(not battle.attack(0, -1), "Chão não é alvo")
	expect(not battle.visible(Vector2i(2, 1), Vector2i(4, 1)), "Ruína interrompe visão")
	expect(battle.visible(Vector2i(6, 4), Vector2i(9, 4)), "Centro aberto mantém visão")
	battle.units[0].cell = Vector2i(11, 4)
	var hp: int = battle.units[5].hp
	expect(battle.attack(0, 5), "Ataque adjacente causa dano")
	expect(
		battle.units[5].hp == hp - 16,
		"32 físico reduzido a 16 pela resistência de 30% e armadura de 28%"
	)
	expect(not battle.attack(0, 5), "Ação não reutilizável")
	var hero_hp: int = battle.units[0].hp
	battle.active_index = 5
	battle.act_enemy()
	expect(
		battle.initial_summon_done and battle.living_minions() == 2,
		"IA abre invocando mesmo com herói adjacente"
	)
	expect(battle.units[0].hp == hero_hp, "Invocação não inventa dano físico")
	battle.active_index = 0
	battle._refresh_resources(0, 5)
	expect(battle.units[0].actions == 1, "Início do turno renova ação")
	battle.units[5].hp = 1
	expect(battle.attack(0, 5), "Golpe final")
	expect(battle.outcome == "BOSS DEFEATED", "Condição de vitória")
	expect(not battle.move_unit(0, Vector2i(10, 4)), "Fim bloqueia movimento")
	var lost := Battle.new()
	for i in 5:
		lost.units[i].hp = 0
	lost.check_outcome()
	expect(lost.outcome == "GRUPO DERROTADO", "Condição de derrota")
	var pursuit := Battle.new()
	for turn in 1500:
		if not pursuit.outcome.is_empty():
			break
		if pursuit.meteor_window:
			if pursuit.response_index < 0:
				pursuit.resolve_meteor_window()
			else:
				pursuit.meteor_response(
					pursuit.response_index, "stay", pursuit.units[pursuit.response_index].cell
				)
			continue
		if pursuit.units[pursuit.active_index].enemy:
			pursuit.act_enemy()
		pursuit.end_turn()
	expect(pursuit.outcome == "GRUPO DERROTADO", "IA derrota grupo que não age")
	print("Verificações básicas: %d; falhas: %d" % [checks, failures])
	quit(1 if failures else 0)
