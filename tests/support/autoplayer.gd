extends RefCounted
## Estratégia de teste; não participa da IA do jogo.
var casts := {}


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
