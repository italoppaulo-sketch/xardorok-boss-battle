extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
var failures := 0


func expect(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)
	else:
		print("PASS: ", description)


func _initialize() -> void:
	var battle := Battle.new()
	expect(battle.units.size() == 6, "Cinco heróis e um chefe")
	expect(not battle.move_unit(0, Vector2i(-1, 2)), "Limites da arena")
	expect(not battle.move_unit(0, battle.units[1].cell), "Ocupação bloqueia movimento")
	expect(not battle.move_unit(0, Vector2i(7, 2)), "Pilar bloqueia movimento")
	expect(battle.move_unit(0, Vector2i(4, 2)), "Caminho válido")
	expect(battle.units[0].move == 3, "Movimento desconta custo do caminho")
	expect(not battle.move_unit(0, Vector2i(10, 2)), "Orçamento de movimento")
	expect(not battle.attack(0, 5), "Ataque fora de alcance")
	expect(not battle.attack(0, 1), "Sem fogo amigo")
	expect(not battle.attack(0, -1), "Clique no chão não é alvo")
	expect(not battle.visible(Vector2i(6, 2), Vector2i(9, 2)), "Pilar interrompe visão")
	expect(battle.visible(Vector2i(6, 4), Vector2i(9, 4)), "Corredor mantém visão")
	battle.units[0].cell = Vector2i(11, 4)
	var hp: int = battle.units[5].hp
	expect(battle.attack(0, 5), "Ataque adjacente causa dano")
	expect(battle.units[5].hp == hp - battle.units[0].damage, "Dano configurado")
	expect(not battle.attack(0, 5), "Ação não pode ser reutilizada")
	var hero_hp: int = battle.units[0].hp
	battle.enemy_turn()
	expect(battle.units[0].hp < hero_hp, "IA ataca herói adjacente")
	expect(battle.round_number == 2 and battle.units[0].actions == 1, "Próxima rodada renova ações")
	battle.units[5].hp = 1
	expect(battle.attack(0, 5), "Golpe final")
	expect(battle.outcome == "BOSS DEFEATED", "Condição de vitória")
	expect(not battle.move_unit(0, Vector2i(10, 4)), "Fim da partida bloqueia movimento")
	var lost := Battle.new()
	for i in 5:
		lost.units[i].hp = 0
	lost.check_outcome()
	expect(lost.outcome == "GRUPO DERROTADO", "Condição de derrota")
	var pursuit := Battle.new()
	for turn in 120:
		if not pursuit.outcome.is_empty():
			break
		pursuit.enemy_turn()
	expect(pursuit.outcome == "GRUPO DERROTADO", "IA alcança e derrota um grupo inativo")
	print("Falhas: ", failures)
	quit(1 if failures else 0)
