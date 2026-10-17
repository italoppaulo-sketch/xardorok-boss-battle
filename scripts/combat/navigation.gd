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
		var route := path(battle, index, goal)
		if not route.is_empty() and route.size() < shortest:
			shortest = route.size()
			best_path = route
	if not best_path.is_empty() and battle.units[index].move > 0:
		var amount: int = mini(best_path.size(), battle.units[index].move)
		battle.move_unit(index, best_path[amount - 1])
