extends RefCounted


## Acólitos preservam ação/turno/HP do Marco 2 e passam a conjurar o laser definido pelo usuário.
static func act(battle: RefCounted, index: int, target: int) -> void:
	var cell: Vector2i = battle.units[target].cell
	if battle.has_status(index, "silenced"):
		battle.Navigation.pursue(battle, index, target)
		battle.attack(index, target)
		return
	if (
		not battle.can_use(index, "red_laser", cell).is_empty()
		or battle.is_burning_cell(battle.units[index].cell)
	):
		var costs: Dictionary = battle.reachable(index)
		var best: Vector2i = battle.units[index].cell
		var best_score := 999
		for destination in costs:
			var distance: int = battle.distance(destination, cell)
			var route: Array[Vector2i] = battle.Navigation.safe_path(battle, index, destination)
			if route.size() > battle.units[index].move:
				continue
			var score: int = (
				costs[destination]
				+ abs(4 - distance)
				+ battle.FireRules.path_risk(battle, index, route)
				+ (20 if battle.is_burning_cell(destination) else 0)
			)
			if distance > 6:
				score += 100 + distance
			if not battle.visible(destination, cell):
				score += 200
			if score < best_score:
				best = destination
				best_score = score
		battle.move_unit(index, best, true)
	battle.use_ability(index, "red_laser", cell)
