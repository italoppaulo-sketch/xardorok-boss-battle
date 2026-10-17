extends RefCounted


## Efeitos reais, acionados igualmente pela interface, testes e IA.
static func execute(
	b: RefCounted, caster: int, id: String, cell: Vector2i, skill: Dictionary
) -> void:
	var source: Dictionary = b.units[caster]
	var target: int = b.unit_at(cell)
	var crit: bool = b.has_status(caster, "illusion") and skill.has("power") and id != "heal"
	if crit:
		source.statuses.erase("illusion")
	b.record(
		{
			"kind": "cast",
			"source": caster,
			"cell": cell,
			"ability": id,
			"color": skill.color,
			"text": source.name + " — " + skill.name
		}
	)
	match id:
		"skin":
			b.apply_status(caster, "ice_skin", skill.duration)
			b.apply_status(caster, "defense", skill.duration)
		"hammer":
			b.apply_status(caster, "ice_hammer", skill.duration)
		"giant":
			b.apply_status(caster, "giant", skill.duration)
			b.apply_status(caster, "attack", skill.duration)
		"dodge":
			b.apply_status(caster, "evasion", skill.duration)
		"flight":
			b.apply_status(caster, "flight", skill.duration)
			source.move += 2
		"illusion":
			b.apply_status(caster, "illusion", skill.duration)
		"heal":
			var amount: int = mini(skill.power, b.units[target].max_hp - b.units[target].hp)
			b.units[target].hp += amount
			b.record(
				{
					"kind": "heal",
					"target": target,
					"amount": amount,
					"color": skill.color,
					"text": "%s recupera %d HP." % [b.units[target].name, amount]
				}
			)
		"antispell":
			_dispel(b, caster, cell)
		"smoke":
			b.smoke.append(
				{
					"cell": source.cell,
					"radius": b.Config.SMOKE_RADIUS,
					"expires": b.round_number + b.Config.SMOKE_ROUNDS
				}
			)
		"fire_shield":
			b.apply_status(caster, "fire_shield", b.Config.SHIELD_DURATION)
		"fire_aura":
			b.apply_status(caster, "fire_aura", b.Config.AURA_DURATION)
		"meteors":
			b.prepare_meteors(
				b.meteor_centers(cell),
				1,
				(
					b.Config.METEOR_DAMAGE
					+ (b.Config.PHASE_TWO_METEOR_BONUS if b.boss_phase == 2 else 0)
				)
			)
		"summon":
			b.spawn_minions()
		"chain":
			var previous := caster
			var sequence := 0
			for victim in b.chain_targets(target, skill.bounces, skill.jump):
				b.record(
					{
						"kind": "link",
						"sequence": sequence,
						"source": previous,
						"target": victim,
						"color": skill.color,
						"text": ""
					}
				)
				b.deal_damage(
					caster, victim, skill.power, skill.element, crit, false, sequence * 0.12
				)
				sequence += 1
				previous = victim
		_:
			if skill.has("power"):
				var targets: Array[int] = [target]
				if skill.get("radius", 0) > 0:
					targets = b.enemies_in_area(caster, cell, skill.radius)
				for victim in targets:
					for hit in skill.get("hits", 1):
						if source.hp <= 0 or b.units[victim].hp <= 0:
							break
						var power: int = source.damage if skill.power < 0 else skill.power
						var element: String = skill.get("element", "physical")
						var contact: bool = (
							b.distance(source.cell, b.units[victim].cell) <= 2
							and b.skill_range(caster, id) <= 2
						)
						var dealt: int = b.deal_damage(
							caster, victim, power, element, crit, contact, hit * 0.18
						)
						if dealt > 0 and b.units[victim].hp > 0:
							if skill.has("status"):
								b.apply_status(victim, skill.status, skill.duration)
							if b.has_status(caster, "ice_hammer") and contact:
								b.deal_damage(caster, victim, 12, "ice", false, false, hit * 0.18)
								if b.chance(0.35):
									b.apply_status(victim, "frozen", 1)
			elif skill.has("status"):
				b.apply_status(target, skill.status, skill.duration)

	b.record_world()


static func _dispel(b: RefCounted, caster: int, cell: Vector2i) -> void:
	var removed := 0
	for zone in b.smoke.duplicate():
		if Vector2(cell).distance_to(Vector2(zone.cell)) <= zone.radius:
			b.smoke.erase(zone)
			removed += 1
	for mark in b.meteors.duplicate():
		if b.distance(cell, mark.cell) <= mark.radius:
			b.meteors.erase(mark)
			removed += 1
	var target: int = b.unit_at(cell)
	if target >= 0:
		var previous: Dictionary = b.units[target].statuses.duplicate()
		removed += b.Statuses.dispel(
			b.units[target], b.units[target].enemy == b.units[caster].enemy
		)
		for id in previous:
			if not b.units[target].statuses.has(id):
				b.boss_effect_removed(target, id)
				b.record(
					{
						"kind": "expire",
						"target": target,
						"status_id": id,
						"text": "%s dissipado." % b.Statuses.DEFINITIONS[id].name
					}
				)

	b.record(
		{
			"kind": "dispel",
			"cell": cell,
			"color": "9cbfff",
			"text": "Antispell remove %d efeito(s)." % removed
		}
	)
