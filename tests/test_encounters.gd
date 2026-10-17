extends SceneTree
## Partidas completas desde as posições originais, sem alterar HP ou recursos.
const Battle = preload("res://scripts/combat/battle.gd")
var failures := 0
var wins := 0
var losses := 0
var strategy := preload("res://tests/support/autoplayer.gd").new()


func invariant(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _initialize() -> void:
	for seed_value in 20:
		var battle := Battle.new()
		battle.rng.seed = seed_value + 17
		for turn in 35:
			if not battle.outcome.is_empty():
				break
			for hero in 5:
				if battle.units[hero].hp > 0:
					strategy.play_hero(battle, hero)
				check_integrity(battle)
				if not battle.outcome.is_empty():
					break
			if battle.outcome.is_empty():
				battle.enemy_turn()
			check_integrity(battle)
		if battle.outcome == "BOSS DEFEATED":
			wins += 1
		elif battle.outcome == "GRUPO DERROTADO":
			losses += 1
		else:
			invariant(false, "Partida não termina em até 35 rodadas, seed %d" % seed_value)
	invariant(wins > 0, "Estratégia automatizada precisa conseguir vencer desde posições originais")
	print(
		(
			"Partidas completas: %d vitórias, %d derrotas; falhas: %d; habilidades usadas: %s"
			% [wins, losses, failures, str(strategy.casts.keys())]
		)
	)
	quit(1 if failures else 0)


func check_integrity(b: RefCounted) -> void:
	var occupied := {}
	for unit in b.units:
		invariant(unit.hp >= 0 and unit.hp <= unit.max_hp, "HP permanece dentro dos limites")
		invariant(
			unit.mana >= 0 and unit.mana <= unit.max_mana, "Mana permanece dentro dos limites"
		)
		invariant(
			unit.actions >= 0 and unit.bonus >= 0 and unit.move >= 0, "Recursos nunca negativos"
		)
		if unit.hp <= 0:
			continue
		invariant(b.inside(unit.cell) and unit.cell not in b.WALLS, "Unidades vivas em chão válido")
		invariant(not occupied.has(unit.cell), "Sem sobreposição de unidades vivas")
		occupied[unit.cell] = true
		for id in unit.statuses:
			invariant(unit.statuses[id] > 0, "Não restam estados expirados")
	invariant(b.living_minions() <= 3, "Número de lacaios respeita limite")
