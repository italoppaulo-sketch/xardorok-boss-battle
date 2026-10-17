extends RefCounted


## Pontuação contextual sobre alvos percebidos; memória não é visão atual.
static func choose(b: RefCounted) -> Dictionary:
	if not b.initial_summon_done and b.can_use(5, "summon", b.units[5].cell).is_empty():
		return {"id": "summon", "cell": b.units[5].cell}
	var target: int = nearest_hero(b, 5)
	if target < 0:
		# Invocação e cobertura não precisam de uma vítima percebida.
		if (
			b.living_minions() < b.Config.MAX_MINIONS
			and b.can_use(5, "summon", b.units[5].cell).is_empty()
		):
			return {"id": "summon", "cell": b.units[5].cell}
		return {}
	var options: Array[Dictionary] = []
	var cell: Vector2i = b.units[target].cell
	if b.can_use(5, "basic", cell).is_empty():
		var lethal: bool = b.units[target].hp <= b.units[5].damage
		options.append(
			{
				"id": "basic",
				"cell": cell,
				"score":
				(
					b.Config.AI_WEIGHTS.physical
					+ (80 if lethal else 0)
					+ (12 if b.boss_phase == 2 else 0)
				)
			}
		)
	var ranged := 0
	var cluster := 0
	for i in 5:
		if b.units[i].hp <= 0 or not b.can_observe(5, i):
			continue
		if b.distance(b.units[5].cell, b.units[i].cell) > 2:
			ranged += 1
		var perceived_cluster := 0
		for hero in b.heroes_in_area(b.units[i].cell, 1):
			if b.can_observe(5, hero):
				perceived_cluster += 1
		cluster = maxi(cluster, perceived_cluster)
	var nearby: int = b.heroes_in_area(b.units[5].cell, 2).size()
	var scores := {
		"fire_shield":
		(
			80
			+ nearby * 15
			+ mini(70, b.boss_damage_since_turn)
			+ (30 if b.units[5].hp < b.units[5].max_hp * 0.8 else 0)
		),
		"meteors":
		b.Config.AI_WEIGHTS.meteors + ranged * 6 + cluster * 20 + (14 if b.boss_phase == 2 else 0),
		"summon":
		b.Config.AI_WEIGHTS.summon + (18 if b.boss_phase == 2 else 0) - b.living_minions() * 35,
		"smoke":
		(
			b.Config.AI_WEIGHTS.smoke
			+ ranged * 14
			+ b.living_minions() * 12
			+ (25 if b.units[5].hp < b.units[5].max_hp * 0.7 else 0)
			+ (35 if b.boss_phase == 2 else 0)
		)
	}
	for id in scores:
		var destination: Vector2i = cell if id == "meteors" else b.units[5].cell
		if id == "smoke" and not b.smoke.is_empty():
			continue
		if id == "summon" and b.living_minions() >= b.Config.MAX_MINIONS:
			continue
		if b.can_use(5, id, destination).is_empty():
			options.append({"id": id, "cell": destination, "score": scores[id]})
	options.sort_custom(func(a: Dictionary, c: Dictionary): return a.score > c.score)
	return options[0] if not options.is_empty() else {}


static func wants_aura(b: RefCounted) -> bool:
	return (
		b.can_use(5, "fire_aura", b.units[5].cell).is_empty()
		and not b.heroes_in_area(b.units[5].cell, 2).is_empty()
	)


static func nearest_hero(b: RefCounted, index: int) -> int:
	var result := -1
	var closest := 999
	for i in 5:
		if b.units[i].hp > 0 and b.can_observe(index, i):
			var d: int = b.distance(b.units[index].cell, b.units[i].cell)
			if d < closest:
				result = i
				closest = d
	return result


static func search_last_seen(b: RefCounted, index: int) -> void:
	var costs: Dictionary = b.reachable(index)
	var last := Vector2i(-1, -1)
	var closest := 999
	for hero in 5:
		var cell: Vector2i = b.last_seen(index, hero)
		if not b.inside(cell):
			continue
		var d: int = b.distance(b.units[index].cell, cell)
		if d < closest:
			closest = d
			last = cell
	if last.x < 0:
		return
	var best: Vector2i = b.units[index].cell
	var score := 9999
	for destination in costs:
		var value: int = b.distance(destination, last) * 10 + costs[destination]
		if value < score:
			best = destination
			score = value
	b.move_unit(index, best)
