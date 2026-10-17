extends SceneTree
## Partidas completas desde as posições originais, sem alterar HP ou recursos.
const Battle = preload("res://scripts/combat/battle.gd")
var failures := 0
var wins := 0
var losses := 0
var casts := {}


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
					play_hero(battle, hero)
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
			% [wins, losses, failures, str(casts.keys())]
		)
	)
	quit(1 if failures else 0)


func play_hero(b: RefCounted, hero: int) -> void:
	var bonuses := [["giant", "hammer", "skin"], ["dodge"], [], ["flight"], ["illusion"]]
	for id in bonuses[hero]:
		if b.availability(hero, id).is_empty():
			use(b, hero, id, b.units[hero].cell)
			break
	if hero == 2:
		for zone in b.smoke:
			if b.can_use(hero, "antispell", zone.cell).is_empty():
				use(b, hero, "antispell", zone.cell)
				return
		for ally in 5:
			if b.units[ally].hp > 0 and b.units[ally].max_hp - b.units[ally].hp >= 35:
				if b.can_use(hero, "heal", b.units[ally].cell).is_empty():
					use(b, hero, "heal", b.units[ally].cell)
					return
	var preferences := [
		["double", "basic"],
		["fushigiri", "unarmed", "basic"],
		["purple_fire", "basic"],
		["energy_arrow", "ice_arrow", "root_arrow", "basic"],
		["chain", "basic"]
	]
	var chosen := "basic"
	for id in preferences[hero]:
		if b.availability(hero, id).is_empty():
			chosen = id
			break
	var current: Vector2i = b.units[hero].cell
	var destination := current
	var best_score := 9999
	var reachable: Dictionary = b.reachable(hero)
	var reach: int = b.skill_range(hero, chosen)
	for cell in reachable:
		var d: int = b.distance(cell, b.units[5].cell)
		var score: int = reachable[cell]
		if d > reach:
			score += 100 + d * 5
		if not b.visible(cell, b.units[5].cell):
			score += 200
		if reach > 2 and d <= 1:
			score += 50
		for mark in b.meteors:
			if b.distance(cell, mark.cell) <= mark.radius:
				score += 70
		if score < best_score:
			best_score = score
			destination = cell
	b.move_unit(hero, destination)
	for id in preferences[hero]:
		if b.can_use(hero, id, b.units[5].cell).is_empty():
			use(b, hero, id, b.units[5].cell)
			return
	for enemy in range(6, b.units.size()):
		if b.can_use(hero, "basic", b.units[enemy].cell).is_empty():
			use(b, hero, "basic", b.units[enemy].cell)
			return


func use(b: RefCounted, hero: int, id: String, cell: Vector2i) -> void:
	if b.use_ability(hero, id, cell):
		casts[id] = true


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
