extends RefCounted
## Magos preferem distância de 3–5 células, linha de tiro e terreno seguro.


static func act(battle: RefCounted, index: int, target: int) -> void:
	if not battle.valid_unit(target) or battle.units[target].hp <= 0:
		return
	var cell: Vector2i = battle.units[target].cell
	if battle.has_status(index, "silenced"):
		battle.Navigation.pursue(battle, index, target)
		battle.attack(index, target)
		return
	var start: Vector2i = battle.units[index].cell
	var costs: Dictionary = battle.reachable(index)
	var best := start
	var best_score := position_score(battle, index, start, cell, 0)
	for destination in costs:
		if destination == start:
			continue
		var route: Array[Vector2i] = battle.Navigation.safe_path(battle, index, destination)
		if route.is_empty() or route.size() > battle.units[index].move:
			continue
		var score := position_score(battle, index, destination, cell, route.size())
		score += battle.FireRules.path_risk(battle, index, route) * 4
		if score < best_score:
			best = destination
			best_score = score
	# Se nenhuma célula alcançável oferece tiro, avance pelo caminho até uma posição
	# de tiro futura. Distância Manhattan isolada não contorna ruínas em forma de U.
	if best == start and not battle.visible(start, cell):
		best = approach_firing_position(battle, index, cell)
	if best != start:
		battle.move_unit(index, best, true)
	if battle.units[index].hp > 0:
		battle.use_ability(index, "red_laser", cell)


static func position_score(
	battle: RefCounted, index: int, destination: Vector2i, target: Vector2i, steps: int
) -> int:
	var distance: int = battle.distance(destination, target)
	var laser_range: int = battle.Abilities.get_skill("red_laser").range
	var score := steps * 2
	if distance < 3:
		score += (3 - distance) * 28
	elif distance > 5:
		score += (distance - 5) * 20
	if distance > laser_range:
		score += 90
	if not battle.visible(destination, target):
		score += 180
	if battle.is_burning_cell(destination):
		score += 150
	# Não se encoste em outro herói apenas para ganhar distância do alvo primário.
	for hero in 5:
		if battle.units[hero].hp > 0 and battle.can_observe(index, hero):
			if battle.distance(destination, battle.units[hero].cell) <= 1:
				score += 35
	return score


static func approach_firing_position(battle: RefCounted, index: int, target: Vector2i) -> Vector2i:
	var start: Vector2i = battle.units[index].cell
	if battle.has_status(index, "rooted") or battle.has_status(index, "frozen"):
		return start
	var found: Dictionary = battle.Navigation.search(battle, index, 200)
	var best_path: Array[Vector2i] = []
	var best_score := 100000
	for destination in found.costs:
		var distance: int = battle.distance(destination, target)
		if distance < 3 or distance > 5 or not battle.visible(destination, target):
			continue
		var route: Array[Vector2i] = battle.Navigation.safe_path(battle, index, destination)
		if route.is_empty():
			continue
		var score: int = route.size() + battle.FireRules.path_risk(battle, index, route) * 4
		if score < best_score:
			best_score = score
			best_path = route
	var steps: int = mini(best_path.size(), battle.units[index].move)
	return best_path[steps - 1] if steps > 0 else start
