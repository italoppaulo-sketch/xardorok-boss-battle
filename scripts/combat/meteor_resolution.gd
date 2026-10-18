extends RefCounted
## Subfase de resposta: nenhum turno extra, refresh ou relógio real.


static func threatened(b: RefCounted, cell: Vector2i) -> bool:
	for mark in b.meteors:
		if b.distance(cell, mark.cell) <= mark.radius:
			return true
	return false


static func prepare(b: RefCounted, centers: Array[Vector2i], radius: int, power: int) -> void:
	if b.meteor_window or not b.outcome.is_empty():
		return
	for center in centers:
		b.meteors.append({"cell": center, "radius": radius, "power": power, "due": b.round_number})
	b.meteor_guards.clear()
	b.response_queue.clear()
	for i in 5:
		if b.units[i].hp > 0 and threatened(b, b.units[i].cell):
			b.response_queue.append(i)
	b.meteor_window = true
	b.response_index = b.response_queue.pop_front() if not b.response_queue.is_empty() else -1
	b.record_world()


static func destinations(b: RefCounted, index: int) -> Dictionary:
	var result := {}
	if (
		not b.valid_unit(index)
		or b.units[index].hp <= 0
		or b.units[index].get("defensive_reaction", 0) < 1
	):
		return result
	var search: Dictionary = b.Navigation.search(b, index, b.Config.EMERGENCY_DISTANCE)
	for cell in search.costs:
		if (
			cell == b.units[index].cell
			or cell in b.WALLS
			or b.unit_at(cell) >= 0
			or threatened(b, cell)
		):
			continue
		result[cell] = search.costs[cell]
	return result


static func can_respond(b: RefCounted, index: int, choice: String, destination: Vector2i) -> String:
	if (
		not b.meteor_window
		or index != b.response_index
		or not b.valid_unit(index)
		or b.units[index].hp <= 0
	):
		return "Aguarde sua resposta ao meteoro."
	if choice != "stay" and b.units[index].get("defensive_reaction", 0) < 1:
		return "Sem Reação Defensiva: renova no início da próxima rodada."
	match choice:
		"stay":
			return ""
		"guard":
			return "Congelamento impede defesa." if b.has_status(index, "frozen") else ""
		"evade":
			return (
				""
				if destinations(b, index).has(destination)
				else "Evasão exige destino livre fora das marcas em até 2 passos; raiz/gelo impedem."
			)

	return "Resposta desconhecida."


static func respond(b: RefCounted, index: int, choice: String, destination: Vector2i) -> bool:
	if not can_respond(b, index, choice, destination).is_empty():
		return false
	if choice == "guard":
		b.units[index].defensive_reaction -= 1
		b.record(
			{
				"kind": "guard",
				"source": index,
				"target": index,
				"color": "84cfee",
				"text":
				"%s assume defesa emergencial: impacto reduzido em 50%%." % b.units[index].name
			}
		)
		b.meteor_guards[index] = true
	elif choice == "evade":
		var origin: Vector2i = b.units[index].cell
		var steps: Array[Vector2i] = b.Navigation.path(b, index, destination)
		b.units[index].defensive_reaction -= 1
		var consumed_now: bool = index == b.active_index and b.units[index].actions > 0
		if consumed_now:
			b.units[index].actions -= 1
		else:
			b.emergency_action_debt[index] = int(b.emergency_action_debt.get(index, 0)) + 1
		b.record(
			{
				"kind": "action_sacrifice",
				"source": index,
				"when": "current" if consumed_now else "next",
				"text":
				(
					"%s compromete %s ação principal."
					% [b.units[index].name, "a atual" if consumed_now else "a próxima"]
				)
			}
		)
		b.units[index].cell = destination
		b.record(
			{
				"kind": "move",
				"source": index,
				"from": origin,
				"cell": destination,
				"path": steps,
				"text": ""
			}
		)
		b.FireRules.on_route(b, index, steps)
		b.remember_positions()
	b.record(
		{
			"kind": "meteor_response",
			"source": index,
			"response": choice,
			"text": "%s — resposta ao meteoro: %s." % [b.units[index].name, choice]
		}
	)
	b.response_index = -1
	while not b.response_queue.is_empty():
		var next: int = b.response_queue.pop_front()
		if b.units[next].hp > 0:
			b.response_index = next
			break
	if b.response_index < 0:
		resolve(b)
	return true


static func resolve(b: RefCounted) -> void:
	if not b.meteor_window:
		return
	var marks: Array = b.meteors.duplicate(true)
	b.meteors.clear()
	b.meteor_window = false
	b.response_index = -1
	b.response_queue.clear()
	for mark in marks:
		b.record(
			{
				"kind": "meteor",
				"cell": mark.cell,
				"radius": mark.radius,
				"color": "ff905a",
				"text": "Meteoro impacta a área anunciada!"
			}
		)
		for hero in b.heroes_in_area(mark.cell, mark.radius):
			var power: int = roundi(mark.power * (0.5 if b.meteor_guards.has(hero) else 1.0))
			b.deal_damage(5, hero, power, "fire", false, false, 0.0, "meteor")
		b.FireRules.ignite(b, mark.cell, mark.radius)
	b.meteor_guards.clear()
	b.record_world()
	b.check_outcome()


static func cancel(b: RefCounted) -> void:
	b.meteor_window = false
	b.response_index = -1
	b.response_queue.clear()
	b.meteor_guards.clear()
	b.meteors.clear()
	b.record_world()
