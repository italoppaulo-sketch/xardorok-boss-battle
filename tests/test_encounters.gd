extends SceneTree
## 36 partidas sem adulterar HP, recursos, iniciativa ou resultado.
const Battle = preload("res://scripts/combat/battle.gd")
const Strategy = preload("res://tests/support/autoplayer.gd")
var failures := 0
var results: Array[Dictionary] = []


func invariant(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _initialize() -> void:
	for policy in Strategy.POLICIES:
		for seed_value in [17, 42, 99]:
			results.append(play(policy, seed_value))
	var file := FileAccess.open("res://docs/balanceamento_marco52.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"godot": Engine.get_version_info().string,
				"policies": Strategy.POLICIES,
				"matches": results
			},
			"\t"
		)
	)
	print("BALANCEAMENTO: ", JSON.stringify(results))
	print("Partidas completas: %d; falhas de integridade: %d" % [results.size(), failures])
	quit(1 if failures else 0)


func play(policy: String, seed_value: int) -> Dictionary:
	var b := Battle.new()
	b.rng.seed = seed_value
	var strategy := Strategy.new()
	strategy.policy = policy
	var stats := {
		"strategy": policy,
		"seed": seed_value,
		"rounds": 0,
		"result": "",
		"hero_hp": [],
		"boss_hp": 0,
		"actions": 0,
		"casts": {},
		"boss_damage": 0,
		"minion_damage": 0,
		"physical": 0,
		"meteors": 0,
		"smoke": 0,
		"summons": 0,
		"reactions": 0,
		"phase_two": false,
		"meteor_hits": 0,
		"meteor_impacts": 0,
		"evades": 0,
		"actions_sacrificed": 0,
		"guards": 0,
		"shield": 0,
		"aura": 0,
		"aura_damage": 0,
		"shield_damage": 0,
		"floor_damage": 0,
		"hero_casts": {},
		"minions_spawned": 0,
		"minions_defeated": 0,
		"minion_moves": 0,
		"minion_attacks": 0,
		"meteor_damage": 0,
		"defensive_reactions_spent": 0,
		"decision_steps": 0,
		"elapsed_ms": 0
	}
	var started := Time.get_ticks_msec()
	for step in 1800:
		stats.decision_steps = step + 1
		if not b.outcome.is_empty() or b.round_number > 80:
			break
		b.events.clear()
		if b.meteor_window:
			strategy.respond_meteor(b)
			collect(stats, b.events)
			check_integrity(b)
			continue
		var actor: int = b.active_index
		if b.units[actor].enemy:
			b.act_enemy()
		else:
			strategy.play_hero(b, actor)
		collect(stats, b.events)
		check_integrity(b)
		b.events.clear()
		if b.outcome.is_empty() and not b.meteor_window:
			b.end_turn()
		collect(stats, b.events)
		check_integrity(b)
	stats.elapsed_ms = Time.get_ticks_msec() - started
	stats.minions_defeated = 0
	for index in range(6, b.units.size()):
		if b.units[index].hp <= 0:
			stats.minions_defeated += 1
	stats.rounds = b.round_number
	stats.result = b.outcome if not b.outcome.is_empty() else "LIMITE_80_RODADAS"
	stats.boss_hp = b.units[5].hp
	stats.phase_two = b.boss_phase == 2
	for i in 5:
		stats.hero_hp.append(b.units[i].hp)
	return stats


func collect(stats: Dictionary, events: Array[Dictionary]) -> void:
	for event in events:
		var kind: String = event.kind
		if kind == "spawn":
			stats.minions_spawned += 1
		if kind == "move" and event.get("source", -1) >= 6:
			stats.minion_moves += 1
		if kind == "cast":
			stats.actions += 1
			if event.source >= 6:
				stats.minion_attacks += 1
			var id: String = event.ability
			stats.casts[id] = int(stats.casts.get(id, 0)) + 1
			if event.source < 5:
				stats.hero_casts[id] = int(stats.hero_casts.get(id, 0)) + 1
			if event.source == 5:
				if id == "basic":
					stats.physical += 1
				if id == "meteors":
					stats.meteors += 1
				if id == "smoke":
					stats.smoke += 1
				if id == "summon":
					stats.summons += 1
				if id == "fire_shield":
					stats.shield += 1
				if id == "fire_aura":
					stats.aura += 1
		if kind == "meteor":
			stats.meteor_impacts += 1
		if kind == "meteor_response":
			if event.get("response", "") == "evade":
				stats.evades += 1
				stats.defensive_reactions_spent += 1
				stats.actions_sacrificed += 1
			elif event.get("response", "") == "guard":
				stats.guards += 1
				stats.defensive_reactions_spent += 1
		if kind == "reaction":
			stats.reactions += 1
		if kind == "damage" and event.target < 5:
			match event.get("cause", ""):
				"meteor":
					stats.meteor_hits += 1
					stats.meteor_damage += event.amount
				"aura":
					stats.aura_damage += event.amount
				"shield":
					stats.shield_damage += event.amount
				"floor":
					stats.floor_damage += event.amount
			if event.get("source", -1) == 5 or event.get("source", -1) < 0:
				stats.boss_damage += event.amount
			else:
				stats.minion_damage += event.amount


func check_integrity(b: RefCounted) -> void:
	var occupied := {}
	for unit in b.units:
		invariant(unit.hp >= 0 and unit.hp <= unit.max_hp, "HP dentro dos limites")
		invariant(unit.mana >= 0 and unit.mana <= unit.max_mana, "PM dentro dos limites")
		invariant(
			unit.actions >= 0 and unit.bonus >= 0 and unit.move >= 0, "Recursos não negativos"
		)
		if unit.hp <= 0:
			continue
		invariant(b.inside(unit.cell) and unit.cell not in b.WALLS, "Unidades em piso válido")
		invariant(not occupied.has(unit.cell), "Sem sobreposição de unidades vivas")
		occupied[unit.cell] = true
		for id in unit.statuses:
			invariant(unit.statuses[id] > 0, "Não restam estados expirados")
	invariant(b.living_minions() <= 4, "Limite de lacaios")
