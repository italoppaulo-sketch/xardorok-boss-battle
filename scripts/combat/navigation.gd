extends RefCounted


## BFS preserva o custo e a ocupação do Marco 1; voo só muda travessia, nunca pouso.
static func search(
	battle: RefCounted, index: int, budget: int, preview: bool = false
) -> Dictionary:
	var start: Vector2i = battle.units[index].cell
	var costs := {start: 0}
	var parents := {}
	var pending: Array[Vector2i] = [start]
	var flying: bool = battle.has_status(index, "flight")
	if battle.has_status(index, "rooted") or battle.has_status(index, "frozen"):
		return {"costs": costs, "parents": parents}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in battle.DIRECTIONS:
			var next: Vector2i = cell + direction
			if not battle.inside(next) or costs.has(next):
				continue
			var occupant: int = battle.unit_at(next)
			if preview and occupant >= 0 and not battle.can_observe(index, occupant):
				occupant = -1
			if not flying and (next in battle.WALLS or occupant != -1):
				continue
			var cost: int = costs[cell] + 1
			if cost <= budget:
				costs[next] = cost
				parents[next] = cell
				pending.append(next)
	return {"costs": costs, "parents": parents}


static func destinations(battle: RefCounted, index: int, preview: bool = false) -> Dictionary:
	var result: Dictionary = search(battle, index, battle.units[index].move, preview).costs
	for cell in result.keys():
		var occupant: int = battle.unit_at(cell)
		if preview and occupant >= 0 and not battle.can_observe(index, occupant):
			occupant = -1
		if cell in battle.WALLS or (occupant != -1 and occupant != index):
			result.erase(cell)
	return result


static func path(battle: RefCounted, index: int, destination: Vector2i) -> Array[Vector2i]:
	var found := search(battle, index, 200)
	var steps: Array[Vector2i] = []
	if not found.costs.has(destination):
		return steps
	var cell := destination
	while cell != battle.units[index].cell:
		steps.push_front(cell)
		cell = found.parents[cell]
	return steps


static func pursue(battle: RefCounted, index: int, target: int) -> void:
	# Busca o melhor destino usando distância real de caminho até as células adjacentes.
	var best_path: Array[Vector2i] = []
	var shortest := 999
	for direction in battle.DIRECTIONS:
		var goal: Vector2i = battle.units[target].cell + direction
		if goal == battle.units[index].cell:
			return
		if not battle.inside(goal) or goal in battle.WALLS or battle.unit_at(goal) != -1:
			continue
		var route := safe_path(battle, index, goal)
		var risk: int = battle.FireRules.path_risk(battle, index, route)
		if not route.is_empty() and route.size() + risk < shortest:
			shortest = route.size() + risk
			best_path = route
	if not best_path.is_empty() and battle.units[index].move > 0:
		var amount: int = mini(best_path.size(), battle.units[index].move)
		battle.move_unit(index, best_path[amount - 1], true)


static func safe_path(battle: RefCounted, index: int, destination: Vector2i) -> Array[Vector2i]:
	# Dijkstra só para a IA: o preço de risco não reduz passos normais do jogador.
	var start: Vector2i = battle.units[index].cell
	var pending: Array[Vector2i] = [start]
	var scores := {start: 0}
	var parents := {}
	while not pending.is_empty():
		pending.sort_custom(func(a: Vector2i, c: Vector2i): return scores[a] < scores[c])
		var cell: Vector2i = pending.pop_front()
		if cell == destination:
			var route: Array[Vector2i] = []
			while cell != start:
				route.push_front(cell)
				cell = parents[cell]
			return route
		for direction in battle.DIRECTIONS:
			var next: Vector2i = cell + direction
			if (
				not battle.inside(next)
				or next in battle.WALLS
				or (battle.unit_at(next) >= 0 and next != start)
			):
				continue
			var step: Array[Vector2i] = [next]
			var score: int = scores[cell] + 1 + battle.FireRules.path_risk(battle, index, step)
			if score < scores.get(next, 100000):
				scores[next] = score
				parents[next] = cell
				if next not in pending:
					pending.append(next)
	return []
