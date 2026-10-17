# gdlint: disable=max-public-methods,max-returns
extends RefCounted
## Regras sem dependência de interface. A grade interna não é desenhada.
const Roster = preload("res://scripts/data/roster.gd")
const Abilities = preload("res://scripts/data/abilities.gd")
const Statuses = preload("res://scripts/combat/statuses.gd")
const Navigation = preload("res://scripts/combat/navigation.gd")
const Executor = preload("res://scripts/abilities/executor.gd")
const BossAI = preload("res://scripts/ai/xardorok_ai.gd")
const SIZE := Vector2i(15, 9)
const WALLS := [Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 5), Vector2i(7, 6)]
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var units: Array[Dictionary] = Roster.create_units()
var round_number := 1
var outcome := ""
var phase := "heroes"
var smoke: Array[Dictionary] = []
var meteors: Array[Dictionary] = []
var events: Array[Dictionary] = []
var history: PackedStringArray = []
var last_error := ""
var random_outcomes := true
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func valid_unit(index: int) -> bool:
	return index >= 0 and index < units.size()


func has_status(index: int, id: String) -> bool:
	return valid_unit(index) and Statuses.has(units[index], id)


func apply_status(index: int, id: String, duration: int) -> bool:
	if not valid_unit(index):
		return false
	var applied := Statuses.apply(units[index], id, duration)
	if applied:
		record(
			{
				"kind": "status",
				"target": index,
				"color": Statuses.DEFINITIONS[id].color,
				"text":
				"%s: %s (%d)." % [units[index].name, Statuses.DEFINITIONS[id].name, duration]
			}
		)
	return applied


func record(event: Dictionary) -> void:
	events.append(event)
	if not event.get("text", "").is_empty():
		history.append(event.text)
		if history.size() > 50:
			history.remove_at(0)


func chance(probability: float) -> bool:
	return probability >= 1.0 or (random_outcomes and rng.randf() < probability)


func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y


func unit_at(cell: Vector2i) -> int:
	for i in units.size():
		if units[i].hp > 0 and units[i].cell == cell:
			return i
	return -1


func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func reachable(index: int) -> Dictionary:
	return Navigation.destinations(self, index) if valid_unit(index) else {}


func move_unit(index: int, destination: Vector2i) -> bool:
	if not outcome.is_empty() or not valid_unit(index) or units[index].hp <= 0:
		return false
	if units[index].enemy != (phase == "enemies"):
		return false
	var costs := reachable(index)
	if not costs.has(destination) or destination == units[index].cell:
		return false
	var steps := Navigation.path(self, index, destination)
	var start: Vector2i = units[index].cell
	units[index].move -= costs[destination]
	units[index].cell = destination
	record(
		{
			"kind": "move",
			"source": index,
			"from": start,
			"cell": destination,
			"path": steps,
			"text": ""
		}
	)
	return true


func visible(a: Vector2i, b: Vector2i) -> bool:
	for zone in smoke:
		var center := Vector2(zone.cell)
		var from_inside: bool = Vector2(a).distance_to(center) <= zone.radius
		var to_inside: bool = Vector2(b).distance_to(center) <= zone.radius
		var closest := Geometry2D.get_closest_point_to_segment(center, Vector2(a), Vector2(b))
		if not (from_inside and to_inside) and closest.distance_to(center) <= zone.radius:
			return false
	# Segmento entre centros; interseção conservadora com cada obstáculo quadrado.
	var start := Vector2(a) + Vector2(0.5, 0.5)
	var finish := Vector2(b) + Vector2(0.5, 0.5)
	for wall in WALLS:
		var rect := Rect2(Vector2(wall), Vector2.ONE)
		var corners := [
			rect.position, rect.position + Vector2(1, 0), rect.end, rect.position + Vector2(0, 1)
		]
		for edge in 4:
			if (
				Geometry2D.segment_intersects_segment(
					start, finish, corners[edge], corners[(edge + 1) % 4]
				)
				!= null
			):
				return false
	return true


func attack(attacker: int, target: int) -> bool:
	if not valid_unit(target):
		return false
	return use_ability(attacker, "basic", units[target].cell)


func skill_range(index: int, id: String) -> int:
	var skill := Abilities.get_skill(id)
	var reach: int = skill.get("range", 0)
	if reach < 0:
		reach = units[index].range
	if has_status(index, "giant") and skill.get("element", "") == "physical" and reach <= 2:
		reach += 1
	return reach


func availability(index: int, id: String) -> String:
	if not outcome.is_empty() or not valid_unit(index) or units[index].hp <= 0:
		return "Personagem indisponível."
	var unit: Dictionary = units[index]
	var skill := Abilities.get_skill(id)
	if skill.is_empty() or (id != "basic" and id not in Abilities.loadout(index)):
		return "Habilidade não pertence a este personagem."
	if unit.enemy != (phase == "enemies"):
		return "Aguarde sua fase."
	if has_status(index, "frozen"):
		return "Congelamento impede ações e movimento."
	if skill.get("magic", false) and has_status(index, "silenced"):
		return "Silêncio impede conjuração."
	if unit.get("bonus" if skill.get("bonus", false) else "actions", 0) <= 0:
		return "Sem ação bônus." if skill.get("bonus", false) else "Sem ação principal."
	if unit.mana < skill.get("mana", 0) or unit.hp <= skill.get("hp_cost", 0):
		return "Mana ou HP insuficiente."
	if id == "summon" and living_minions() >= 3:
		return "Limite de lacaios."
	if unit.cooldowns.get(id, 0) > 0:
		return "Habilidade em recarga."
	return ""


func can_use(index: int, id: String, cell: Vector2i) -> String:
	var error := availability(index, id)
	if not error.is_empty():
		return error
	var unit: Dictionary = units[index]
	var skill := Abilities.get_skill(id)
	if skill.target == "self":
		return ""
	if not inside(cell) or distance(unit.cell, cell) > skill_range(index, id):
		return "Alvo fora do alcance."
	if skill.get("los", true) and not visible(unit.cell, cell):
		return "Linha de visão bloqueada."
	var target := unit_at(cell)
	if skill.target in ["enemy", "ally"]:
		if target < 0 or units[target].hp <= 0:
			return "Escolha um alvo vivo."
		if (unit.enemy != units[target].enemy) != (skill.target == "enemy"):
			return "Tipo de alvo inválido."
	return ""


func use_ability(index: int, id: String, cell: Vector2i) -> bool:
	last_error = can_use(index, id, cell)
	if not last_error.is_empty():
		return false
	var unit: Dictionary = units[index]
	var skill := Abilities.get_skill(id)
	unit["bonus" if skill.get("bonus", false) else "actions"] -= 1
	unit.mana -= skill.get("mana", 0)
	if skill.get("hp_cost", 0) > 0:
		unit.hp -= skill.hp_cost
		record(
			{
				"kind": "recoil",
				"target": index,
				"amount": skill.hp_cost,
				"color": "bc7cff",
				"text": "%s sacrifica %d HP." % [unit.name, skill.hp_cost]
			}
		)
	if skill.get("cooldown", 0) > 0:
		unit.cooldowns[id] = skill.cooldown
	Executor.execute(self, index, id, unit.cell if skill.target == "self" else cell, skill)
	check_outcome()
	return true


func deal_damage(
	source: int,
	target: int,
	power: int,
	element: String,
	forced_critical: bool = false,
	contact: bool = false,
	delay: float = 0.0
) -> int:
	if not valid_unit(target) or units[target].hp <= 0:
		return 0
	var victim: Dictionary = units[target]
	if element == "physical":
		var evasion: float = victim.evasion + (0.3 if has_status(target, "evasion") else 0.0)
		if chance(evasion):
			record(
				{
					"kind": "miss",
					"target": target,
					"delay": delay,
					"color": "d1c2fa",
					"text": victim.name + " esquivou!"
				}
			)
			return 0
	var crit := forced_critical or (source >= 0 and chance(0.1))
	var value := float(power) * (1.5 if crit else 1.0)
	if source >= 0 and has_status(source, "attack"):
		value *= 1.35
	value *= 1.0 - float(victim.resistances.get(element, 0.0))
	if has_status(target, "defense"):
		value *= 0.65
	var amount := maxi(1, roundi(value))
	victim.hp = maxi(0, victim.hp - amount)
	record(
		{
			"kind": "damage",
			"source": source,
			"target": target,
			"amount": amount,
			"critical": crit,
			"element": element,
			"delay": delay,
			"color": "ffdb88" if crit else "ffb6a0",
			"text": "%s: %d de %s%s." % [victim.name, amount, element, " — CRÍTICO" if crit else ""]
		}
	)
	if contact and has_status(target, "ice_skin") and valid_unit(source) and units[source].hp > 0:
		deal_damage(-1, source, 8, "ice")
	check_outcome()
	return amount


func enemies_in_area(caster: int, cell: Vector2i, radius: int) -> Array[int]:
	var targets: Array[int] = []
	for i in units.size():
		if (
			units[i].hp > 0
			and units[i].enemy != units[caster].enemy
			and distance(cell, units[i].cell) <= radius
		):
			targets.append(i)
	return targets


func heroes_in_area(cell: Vector2i, radius: int) -> Array[int]:
	return enemies_in_area(5, cell, radius)


func chain_targets(first: int, count: int, jump: int) -> Array[int]:
	var result: Array[int] = [first]
	while result.size() < count:
		var previous: int = result.back()
		var closest := jump + 1
		var next := -1
		for i in units.size():
			if units[i].hp <= 0 or not units[i].enemy or i in result:
				continue
			var d := distance(units[previous].cell, units[i].cell)
			if d < closest and visible(units[previous].cell, units[i].cell):
				next = i
				closest = d
		if next < 0:
			break
		result.append(next)
	return result


func check_outcome() -> void:
	if units[5].hp <= 0:
		outcome = "BOSS DEFEATED"
		return
	for unit in units:
		if not unit.enemy and unit.hp > 0:
			return
	outcome = "GRUPO DERROTADO"


func living_minions() -> int:
	var total := 0
	for i in range(6, units.size()):
		if units[i].hp > 0:
			total += 1
	return total


func spawn_minions() -> void:
	if living_minions() >= 3:
		return
	var spawned := 0
	# Expande a busca a partir do chefe, sem reutilizar células ocupadas ou pilares.
	for radius in range(1, 5):
		for y in SIZE.y:
			for x in SIZE.x:
				var cell := Vector2i(x, y)
				if distance(cell, units[5].cell) != radius or cell in WALLS or unit_at(cell) >= 0:
					continue
				var minion: Dictionary = units[5].duplicate(true)
				minion.merge(
					{
						"name": "Cinza %d" % (units.size() - 5),
						"hp": 60,
						"max_hp": 60,
						"damage": 14,
						"cell": cell,
						"color": Color("bf8c73"),
						"statuses": {},
						"cooldowns": {},
						"evasion": 0.05,
						"resistances": {"fire": 0.25},
						"spawn_round": round_number
					},
					true
				)
				units.append(minion)
				record(
					{
						"kind": "spawn",
						"target": units.size() - 1,
						"cell": cell,
						"color": "ff905a",
						"text": "Guerreiro de cinzas invocado."
					}
				)
				spawned += 1
				if spawned >= 2 or living_minions() >= 3:
					return


func meteor_centers(first: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [first]
	var best := -1
	var best_score := -1
	for i in 5:
		if units[i].hp <= 0 or distance(units[i].cell, first) <= 2:
			continue
		var score: int = heroes_in_area(units[i].cell, 1).size()
		if score > best_score:
			best_score = score
			best = i
	if best >= 0:
		result.append(units[best].cell)
	return result


func _tick_statuses(index: int) -> void:
	if units[index].hp <= 0:
		return
	if has_status(index, "burning"):
		deal_damage(-1, index, 8, "fire")
	for id in Statuses.expire(units[index]):
		record(
			{
				"kind": "expire",
				"target": index,
				"color": Statuses.DEFINITIONS[id].color,
				"text": "%s: %s terminou." % [units[index].name, Statuses.DEFINITIONS[id].name]
			}
		)


func _refresh_resources(index: int, movement: int) -> void:
	var unit: Dictionary = units[index]
	unit.move = movement + (2 if has_status(index, "flight") else 0)
	unit.actions = 1
	unit.bonus = 1
	unit.mana = mini(unit.max_mana, unit.mana + 8)
	for id in unit.cooldowns.keys():
		unit.cooldowns[id] = maxi(0, unit.cooldowns[id] - 1)


func _resolve_world() -> void:
	for zone in smoke.duplicate():
		if zone.expires <= round_number:
			smoke.erase(zone)
	for mark in meteors.duplicate():
		if mark.due > round_number:
			continue
		meteors.erase(mark)
		record(
			{
				"kind": "meteor",
				"cell": mark.cell,
				"color": "ff905a",
				"text": "Meteoro impacta a área marcada!"
			}
		)
		for hero in heroes_in_area(mark.cell, mark.radius):
			deal_damage(-1, hero, 40, "fire")


func _aura() -> void:
	if units[5].hp <= 0:
		return
	for i in heroes_in_area(units[5].cell, 1):
		deal_damage(-1, i, 10, "fire")
		if units[i].hp > 0 and chance(0.35):
			apply_status(i, "burning", 2)


func enemy_turn() -> String:
	if not outcome.is_empty():
		return outcome
	events.clear()
	for i in 5:
		_tick_statuses(i)
	check_outcome()
	if not outcome.is_empty():
		return outcome
	phase = "enemies"
	_resolve_world()
	_aura()
	if outcome.is_empty():
		_refresh_resources(5, 4)
		if not has_status(5, "frozen"):
			var target := BossAI.nearest_hero(self, 5)
			if target >= 0:
				Navigation.pursue(self, 5, target)
				var choice := BossAI.choose(self)
				if not choice.is_empty():
					use_ability(5, choice.id, choice.cell)
		_tick_statuses(5)
	for i in range(6, units.size()):
		if not outcome.is_empty():
			break
		if units[i].hp <= 0 or units[i].spawn_round == round_number:
			continue
		_refresh_resources(i, 3)
		if not has_status(i, "frozen"):
			var target := BossAI.nearest_hero(self, i)
			if target >= 0:
				Navigation.pursue(self, i, target)
				attack(i, target)
		_tick_statuses(i)
	if outcome.is_empty():
		round_number += 1
		phase = "heroes"
		for i in 5:
			_refresh_resources(i, 5)
	return "Fase inimiga concluída. Rodada %d." % round_number if outcome.is_empty() else outcome
