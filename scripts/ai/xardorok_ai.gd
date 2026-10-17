extends RefCounted


## Escolha por pontuação contextual; não há ciclo de golpes roteirizado.
static func choose(b: RefCounted) -> Dictionary:
	var target: int = nearest_hero(b, 5)
	if target < 0:
		return {}
	var options: Array[Dictionary] = []
	var cell: Vector2i = b.units[target].cell
	if b.can_use(5, "basic", cell).is_empty():
		var lethal: bool = b.units[target].hp <= b.units[5].damage
		options.append({"id": "basic", "cell": cell, "score": 95 + (80 if lethal else 0)})
	var ranged := 0
	var cluster := 0
	for i in 5:
		if b.units[i].hp <= 0:
			continue
		if b.distance(b.units[5].cell, b.units[i].cell) > 2:
			ranged += 1
		cluster = maxi(cluster, b.heroes_in_area(b.units[i].cell, 1).size())
	var low: bool = b.units[5].hp < b.units[5].max_hp * 0.5
	var scores := {
		"meteors": 55 + ranged * 5 + cluster * 8,
		"summon": 75 + (20 if low else 0) - b.living_minions() * 20,
		"smoke": 50 + ranged * 7 + (25 if low else 0)
	}
	for id in scores:
		var destination: Vector2i = cell if id == "meteors" else b.units[5].cell
		if id == "smoke" and not b.smoke.is_empty():
			continue
		if id == "summon" and b.living_minions() >= 3:
			continue
		if b.can_use(5, id, destination).is_empty():
			options.append({"id": id, "cell": destination, "score": scores[id]})
	options.sort_custom(func(a: Dictionary, c: Dictionary): return a.score > c.score)
	return options[0] if not options.is_empty() else {}


static func nearest_hero(b: RefCounted, index: int) -> int:
	var result := -1
	var closest := 999
	for i in 5:
		if b.units[i].hp > 0:
			var d: int = b.distance(b.units[index].cell, b.units[i].cell)
			if d < closest:
				result = i
				closest = d
	return result
