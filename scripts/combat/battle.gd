# gdlint: disable=max-public-methods,max-returns
extends RefCounted
## Regras sem dependência de interface. A grade interna não é desenhada.
const Roster = preload("res://scripts/data/roster.gd")
const Abilities = preload("res://scripts/data/abilities.gd")
const Statuses = preload("res://scripts/combat/statuses.gd")
const Navigation = preload("res://scripts/combat/navigation.gd")
const Executor = preload("res://scripts/abilities/executor.gd")
const MinionAI = preload("res://scripts/ai/minion_ai.gd")
const BossAI = preload("res://scripts/ai/xardorok_ai.gd")
const Config = preload("res://scripts/data/boss_config.gd")
const Geometry = preload("res://scripts/combat/arena_geometry.gd")
const Initiative = preload("res://scripts/combat/initiative.gd")
const Reactions = preload("res://scripts/combat/reactions.gd")
const Perception = preload("res://scripts/combat/perception.gd")
const MeteorResolution = preload("res://scripts/combat/meteor_resolution.gd")
const FireRules = preload("res://scripts/combat/fire_fields.gd")
const SIZE := Geometry.SIZE
const WALLS := Geometry.WALLS
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var units: Array[Dictionary] = Roster.create_units()
var initiative: Array[int] = []
var active_index := 1
var turn_cursor := 0
var turn_serial := 0
var enemy_acted_serial := -1
var boss_phase := 1
var phase_transition_count := 0
var reactions_used := 0
var hero_turns_ended := 0
var last_hero_index := 1
var perception_memory := {}
var round_number := 1
var outcome := ""
var phase := "heroes"
var smoke: Array[Dictionary] = []
var meteors: Array[Dictionary] = []
var meteor_window := false
var response_index := -1
var response_queue: Array[int] = []
var meteor_guards := {}
var fire_zones: Array[Dictionary] = []
var fire_ticks := {}
var aura_ticks := {}
var emergency_action_debt := {}
var initial_summon_done := false
var boss_damage_since_turn := 0
var events: Array[Dictionary] = []
var history: PackedStringArray = []
var last_error := ""
var random_outcomes := true
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()
	initiative = Initiative.order(units, round_number)
	active_index = initiative[0]
	_refresh_resources(active_index, 5)
	remember_positions()


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
				"status_id": id,
				"turns": duration,
				"target": index,
				"color": Statuses.DEFINITIONS[id].color,
				"text":
				"%s: %s (%d)." % [units[index].name, Statuses.DEFINITIONS[id].name, duration]
			}
		)
	return applied


func record(event: Dictionary) -> void:
	var source: int = event.get("source", -1)
	var target: int = event.get("target", -1)
	event.visible_source = source < 0 or player_visible(source)
	event.visible_target = target < 0 or player_visible(target)
	var public_text: String = event.get("text", "")
	if target >= 0 and not event.visible_target and not public_text.is_empty():
		public_text = "Um efeito ocorre fora da visão."
	elif not public_text.is_empty():
		for i in units.size():
			if not player_visible(i):
				public_text = public_text.replace(units[i].name, "presença oculta")
	event.public_text = public_text
	events.append(event)
	if not public_text.is_empty():
		history.append(public_text)
		if history.size() > 80:
			history.remove_at(0)


func chance(probability: float) -> bool:
	return probability >= 1.0 or (random_outcomes and rng.randf() < probability)


func inside(cell: Vector2i) -> bool:
	return Geometry.valid_cell(cell)


func unit_at(cell: Vector2i) -> int:
	for i in units.size():
		if units[i].hp > 0 and units[i].cell == cell:
			return i
	return -1


func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func reachable(index: int) -> Dictionary:
	return Navigation.destinations(self, index) if valid_unit(index) else {}


func preview_reachable(index: int) -> Dictionary:
	return Navigation.destinations(self, index, true) if valid_unit(index) else {}


func move_unit(index: int, destination: Vector2i, safe_route: bool = false) -> bool:
	if meteor_window or not outcome.is_empty() or not valid_unit(index) or units[index].hp <= 0:
		return false
	if index != active_index:
		return false
	var costs := reachable(index)
	if not costs.has(destination) or destination == units[index].cell:
		return false
	var steps := (
		Navigation.safe_path(self, index, destination)
		if safe_route
		else Navigation.path(self, index, destination)
	)
	if steps.is_empty() or steps.size() > units[index].move:
		return false
	var start: Vector2i = units[index].cell
	units[index].move -= steps.size()
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
	FireRules.on_route(self, index, steps)
	remember_positions()
	return true


func visible(a: Vector2i, b: Vector2i) -> bool:
	return Perception.line(a, b, smoke, WALLS)


func observer_index() -> int:
	if active_index < 5 and units[active_index].hp > 0:
		return active_index
	if units[last_hero_index].hp > 0:
		return last_hero_index
	for i in 5:
		if units[i].hp > 0:
			return i
	return 0


func can_observe(observer: int, target: int) -> bool:
	return (
		valid_unit(observer)
		and valid_unit(target)
		and (observer == target or visible(units[observer].cell, units[target].cell))
	)


func player_visible(index: int) -> bool:
	return (
		valid_unit(index)
		and Perception.presentation_line(
			Vector2(units[observer_index()].cell), Vector2(units[index].cell), smoke
		)
	)


func remember_positions() -> void:
	for observer in units.size():
		if units[observer].hp <= 0:
			continue
		if not perception_memory.has(observer):
			perception_memory[observer] = {}
		for target in units.size():
			if units[target].hp > 0 and can_observe(observer, target):
				perception_memory[observer][target] = units[target].cell


func last_seen(observer: int, target: int) -> Vector2i:
	return perception_memory.get(observer, {}).get(target, Vector2i(-1, -1))


func player_history() -> PackedStringArray:
	return history.duplicate()


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
	if meteor_window or not outcome.is_empty() or not valid_unit(index) or units[index].hp <= 0:
		return "Personagem indisponível."
	var unit: Dictionary = units[index]
	var skill := Abilities.get_skill(id)
	if skill.is_empty() or (id != "basic" and id not in Abilities.loadout(index)):
		return "Habilidade não pertence a este personagem."
	if index != active_index:
		return "Aguarde o turno deste personagem."
	if has_status(index, "frozen"):
		return "Congelamento impede ações e movimento."
	if skill.get("magic", false) and has_status(index, "silenced"):
		return "Silêncio impede conjuração."
	if unit.get("bonus" if skill.get("bonus", false) else "actions", 0) <= 0:
		return "Sem ação bônus." if skill.get("bonus", false) else "Sem ação principal."
	if unit.mana < skill.get("mana", 0) or unit.hp <= skill.get("hp_cost", 0):
		return "Mana ou HP insuficiente."
	if id in ["fire_shield", "fire_aura"] and has_status(index, id):
		return "Efeito já ativo."
	if id == "summon" and living_minions() >= Config.MAX_MINIONS:
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
		unit.cooldowns[id] = (
			Config.COOLDOWNS.get(id, skill.cooldown) if index == 5 else skill.cooldown
		)
	Executor.execute(self, index, id, unit.cell if skill.target == "self" else cell, skill)
	check_outcome()
	remember_positions()
	return true


func deal_damage(
	source: int,
	target: int,
	power: int,
	element: String,
	forced_critical: bool = false,
	contact: bool = false,
	delay: float = 0.0,
	cause: String = ""
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
	var crit := forced_critical or (source >= 0 and cause.is_empty() and chance(0.1))
	var value := float(power) * (1.5 if crit else 1.0)
	if source == 5 and element == "physical" and boss_phase == 2:
		value *= Config.PHASE_TWO_PHYSICAL_MULTIPLIER
	if source >= 0 and has_status(source, "attack"):
		value *= 1.35
	value *= 1.0 - float(victim.resistances.get(element, 0.0))
	if target == 5 and element != "true":
		value *= Config.ARMOR_DAMAGE_MULTIPLIER
	if target == 5 and has_status(5, "fire_shield"):
		value *= Config.SHIELD_DAMAGE_MULTIPLIER
	if has_status(target, "defense"):
		value *= 0.65
	var amount := maxi(1, roundi(value))
	victim.hp = maxi(0, victim.hp - amount)
	if target == 5:
		boss_damage_since_turn += amount
	record(
		{
			"kind": "damage",
			"source": source,
			"target": target,
			"amount": amount,
			"critical": crit,
			"element": element,
			"cause": cause,
			"delay": delay,
			"color": "ffdb88" if crit else "ffb6a0",
			"text": "%s: %d de %s%s." % [victim.name, amount, element, " — CRÍTICO" if crit else ""]
		}
	)
	if contact and has_status(target, "ice_skin") and valid_unit(source) and units[source].hp > 0:
		deal_damage(-1, source, 8, "ice")
	if (
		contact
		and target == 5
		and has_status(5, "fire_shield")
		and valid_unit(source)
		and units[source].hp > 0
	):
		deal_damage(5, source, Config.SHIELD_RETALIATION, "fire", false, false, delay, "shield")
	_update_boss_phase()
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
		if meteor_window:
			MeteorResolution.cancel(self)
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
	var before := living_minions()
	if living_minions() >= Config.MAX_MINIONS:
		return
	var spawned := 0
	# Expande a busca a partir do chefe, sem reutilizar células ocupadas ou pilares.
	for radius in range(1, 5):
		for y in SIZE.y:
			for x in SIZE.x:
				var cell := Vector2i(x, y)
				if (
					not inside(cell)
					or distance(cell, units[5].cell) != radius
					or cell in WALLS
					or unit_at(cell) >= 0
				):
					continue
				var minion: Dictionary = units[5].duplicate(true)
				minion.merge(
					{
						"name": "Acólito %d" % (units.size() - 5),
						"hp": 60,
						"max_hp": 60,
						"damage": 14,
						"cell": cell,
						"color": Color("e74b55"),
						"statuses": {},
						"cooldowns": {},
						"evasion": 0.05,
						"resistances": {"fire": 0.25},
						"spawn_round": round_number,
						"initiative": Config.MINION_INITIATIVE
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
						"text": "Acólito de cinzas invocado."
					}
				)
				spawned += 1
				if living_minions() > before:
					initial_summon_done = true
				if spawned >= Config.MINIONS_PER_SUMMON or living_minions() >= Config.MAX_MINIONS:
					return


func meteor_centers(first: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [first]
	var best := -1
	var best_score := -1
	for i in 5:
		if units[i].hp <= 0 or not can_observe(5, i) or distance(units[i].cell, first) <= 2:
			continue
		var score := 0
		for hero in heroes_in_area(units[i].cell, 1):
			if can_observe(5, hero):
				score += 1
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
		boss_effect_removed(index, id)
		record(
			{
				"kind": "expire",
				"status_id": id,
				"target": index,
				"color": Statuses.DEFINITIONS[id].color,
				"text": "%s: %s terminou." % [units[index].name, Statuses.DEFINITIONS[id].name]
			}
		)


func _refresh_resources(index: int, movement: int) -> void:
	var unit: Dictionary = units[index]
	unit.move = movement + (2 if has_status(index, "flight") else 0)
	unit.actions = 0 if emergency_action_debt.has(index) else 1
	emergency_action_debt.erase(index)
	unit.bonus = 1
	unit.mana = mini(unit.max_mana, unit.mana + 8)
	for id in unit.cooldowns.keys():
		unit.cooldowns[id] = maxi(0, unit.cooldowns[id] - 1)


func _resolve_world() -> void:
	for zone in smoke.duplicate():
		if zone.expires <= round_number:
			smoke.erase(zone)
	FireRules.expire(self)
	record_world()


func _aura(index: int = -1) -> void:
	if index < 0:
		index = active_index
	if index >= 5 or units[index].hp <= 0 or units[5].hp <= 0 or not has_status(5, "fire_aura"):
		return
	var token := "%d:%d" % [turn_serial, index]
	if aura_ticks.has(token) or distance(units[index].cell, units[5].cell) > 1:
		return
	aura_ticks[token] = true
	deal_damage(
		5,
		index,
		Config.AURA_PHASE_TWO_DAMAGE if boss_phase == 2 else Config.AURA_DAMAGE,
		"fire",
		false,
		false,
		0.0,
		"aura"
	)
	if units[index].hp > 0 and chance(0.35):
		apply_status(index, "burning", 2)


func boss_effect_removed(index: int, id: String) -> void:
	if index == 5 and id == "fire_shield":
		units[5].cooldowns.fire_shield = Config.SHIELD_COOLDOWN


func record_world() -> void:
	record(
		{
			"kind": "world",
			"smoke_zones": smoke.duplicate(true),
			"marks": meteors.duplicate(true),
			"fire_zones": fire_zones.duplicate(true),
			"text": ""
		}
	)


func is_burning_cell(cell: Vector2i) -> bool:
	return FireRules.contains(self, cell)


func prepare_meteors(centers: Array[Vector2i], radius: int, power: int) -> void:
	MeteorResolution.prepare(self, centers, radius, power)


func meteor_responses() -> Array[int]:
	var pending: Array[int] = []
	if response_index >= 0:
		pending.append(response_index)
	pending.append_array(response_queue)
	return pending


func emergency_destinations(index: int) -> Dictionary:
	return MeteorResolution.destinations(self, index)


func can_meteor_response(
	index: int, choice: String, destination: Vector2i = Vector2i.ZERO
) -> String:
	return MeteorResolution.can_respond(self, index, choice, destination)


func meteor_response(index: int, choice: String, destination: Vector2i = Vector2i.ZERO) -> bool:
	return MeteorResolution.respond(self, index, choice, destination)


func resolve_meteor_window() -> void:
	if meteor_window and response_index < 0:
		MeteorResolution.resolve(self)


func _update_boss_phase() -> void:
	if (
		boss_phase == 1
		and units[5].hp > 0
		and units[5].hp <= units[5].max_hp * Config.PHASE_THRESHOLD
	):
		boss_phase = 2
		phase_transition_count += 1
		record(
			{
				"kind": "phase",
				"source": 5,
				"cell": units[5].cell,
				"text":
				"FASE 2 — A Ira do Rei. Fogo intensificado; meteoros permitem resposta limitada."
			}
		)


func end_turn() -> String:
	if meteor_window:
		return "Responda ao meteoro iminente."
	if not outcome.is_empty():
		return outcome
	events.clear()
	var previous := active_index
	_tick_statuses(previous)
	_aura(previous)
	FireRules.touch(self, previous)
	check_outcome()
	if not outcome.is_empty():
		return outcome
	if previous < 5:
		Reactions.after_hero_turn(self)
	turn_cursor += 1
	turn_serial += 1
	var guard := 0
	while guard < units.size() * 2 + 2:
		guard += 1
		if turn_cursor >= initiative.size():
			round_number += 1
			_resolve_world()
			fire_ticks.clear()
			aura_ticks.clear()
			reactions_used = 0
			hero_turns_ended = 0
			initiative = Initiative.order(units, round_number)
			turn_cursor = 0
		active_index = initiative[turn_cursor]
		if units[active_index].hp > 0:
			break
		turn_cursor += 1
	phase = "enemies" if units[active_index].enemy else "heroes"
	if active_index < 5:
		last_hero_index = active_index
	_refresh_resources(active_index, 4 if active_index == 5 else (3 if active_index > 5 else 5))
	remember_positions()
	record(
		{
			"kind": "turn",
			"source": active_index,
			"text":
			(
				"Turno de %s · iniciativa %d."
				% [units[active_index].name, units[active_index].initiative]
			)
		}
	)
	return (
		"Turno de %s · rodada %d."
		% [
			units[active_index].name if player_visible(active_index) else "combatente oculto",
			round_number
		]
	)


func act_enemy() -> void:
	if meteor_window or not outcome.is_empty() or active_index < 5 or units[active_index].hp <= 0:
		return
	if enemy_acted_serial == turn_serial:
		return
	enemy_acted_serial = turn_serial
	var index := active_index
	if index == 5:
		_resolve_world()
	if not outcome.is_empty() or has_status(index, "frozen"):
		return
	var target := BossAI.nearest_hero(self, index)
	if index == 5:
		if target >= 0:
			Navigation.pursue(self, 5, target)
		else:
			BossAI.search_last_seen(self, 5)
		if BossAI.wants_aura(self):
			use_ability(5, "fire_aura", units[5].cell)
		var choice := BossAI.choose(self)
		if not choice.is_empty():
			use_ability(5, choice.id, choice.cell)
		boss_damage_since_turn = 0
	elif target >= 0:
		MinionAI.act(self, index, target)
	else:
		BossAI.search_last_seen(self, index)


func enemy_turn() -> String:
	# Compatibilidade de API; agora encerra somente o turno individual ativo.
	return end_turn()
