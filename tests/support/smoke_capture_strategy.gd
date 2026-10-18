extends "res://tests/support/autoplayer.gd"
## Conservative demonstration policy. Production combat rules remain unchanged.
const Catalog = preload("res://scripts/data/abilities.gd")
var conservative := true
var audit: Array[Dictionary] = []
var held_attacks := 0
var dispelled_clouds := 0


func play_hero(b: RefCounted, hero: int) -> void:
	if conservative and hero == 2 and not b.smoke.is_empty():
		if b.availability(hero, "antispell").is_empty():
			var center: Vector2i = b.smoke[0].cell
			var destination: Vector2i = b.units[hero].cell
			var best := 99999
			var reachable: Dictionary = b.reachable(hero)
			for cell in reachable:
				if b.distance(cell, center) <= b.skill_range(hero, "antispell"):
					if int(reachable[cell]) < best:
						best = int(reachable[cell])
						destination = cell
			b.move_unit(hero, destination)
			if b.can_use(hero, "antispell", center).is_empty():
				use(b, hero, "antispell", center)
				return
	super.play_hero(b, hero)


func use(b: RefCounted, hero: int, id: String, cell: Vector2i) -> void:
	var skill: Dictionary = Catalog.get_skill(id)
	var offensive: bool = skill.has("power") and id != "heal"
	if conservative and offensive and not b.smoke.is_empty():
		held_attacks += 1
		return
	var entry := {
		"round": b.round_number,
		"hero": hero,
		"ability": id,
		"offensive": offensive,
		"smoke_count": b.smoke.size(),
		"visible": b.visible(b.units[hero].cell, cell),
		"from": str(b.units[hero].cell),
		"to": str(cell),
		"smoke": str(b.smoke),
	}
	var before: int = b.smoke.size()
	var count: int = int(casts.get(id, 0))
	super.use(b, hero, id, cell)
	entry["executed"] = int(casts.get(id, 0)) > count
	if entry.executed and id == "antispell":
		dispelled_clouds += before - b.smoke.size()
	audit.append(entry)
