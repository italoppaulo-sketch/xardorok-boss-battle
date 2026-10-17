extends RefCounted
## Um dano por combatente/turn_serial, na entrada OU permanência; animações não chamam regras.


static func contains(b: RefCounted, cell: Vector2i) -> bool:
	for zone in b.fire_zones:
		if zone.cell == cell:
			return true
	return false


static func ignite(b: RefCounted, center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if not b.inside(cell) or cell in b.WALLS or b.distance(cell, center) > radius:
				continue
			if contains(b, cell):
				for zone in b.fire_zones:
					if zone.cell == cell:
						zone.expires = b.round_number + b.Config.FIRE_ROUNDS
			else:
				b.fire_zones.append(
					{"cell": cell, "expires": b.round_number + b.Config.FIRE_ROUNDS}
				)


static func expire(b: RefCounted) -> void:
	for zone in b.fire_zones.duplicate():
		if zone.expires <= b.round_number:
			b.fire_zones.erase(zone)


static func touch(b: RefCounted, index: int, forced: bool = false) -> void:
	if (
		not b.valid_unit(index)
		or b.units[index].hp <= 0
		or (not forced and not contains(b, b.units[index].cell))
	):
		return
	var token := "%d:%d" % [b.turn_serial, index]
	if b.fire_ticks.has(token):
		return
	b.fire_ticks[token] = true
	b.deal_damage(-1, index, b.Config.FIRE_DAMAGE, "fire", false, false, 0.0, "floor")


static func on_route(b: RefCounted, index: int, steps: Array[Vector2i]) -> void:
	if b.has_status(index, "flight"):
		touch(b, index)
		return
	for cell in steps:
		if contains(b, cell):
			touch(b, index, true)
			return


static func path_risk(b: RefCounted, index: int, steps: Array[Vector2i]) -> int:
	if b.units[index].resistances.get("fire", 0.0) >= 0.75:
		return 0
	var score := 0
	for cell in steps:
		if contains(b, cell):
			score += 20
	return score
