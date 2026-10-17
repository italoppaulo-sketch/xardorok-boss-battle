extends RefCounted


## Reações não executam turnos nem chamam end_turn: não há cadeia recursiva.
static func after_hero_turn(b: RefCounted) -> void:
	b.hero_turns_ended += 1
	if b.hero_turns_ended % b.Config.HERO_TURNS_PER_REACTION != 0:
		return
	if b.reactions_used >= b.Config.REACTIONS_PER_ROUND or not b.outcome.is_empty():
		return
	if b.units[5].hp <= 0 or b.has_status(5, "frozen") or b.has_status(5, "silenced"):
		return
	var target: int = b.BossAI.nearest_hero(b, 5)
	if target < 0:
		return
	b.reactions_used += 1
	var nearby: int = b.heroes_in_area(b.units[5].cell, 2).size()
	if b.boss_phase == 2 and b.living_minions() > 0 and nearby == 0:
		b.record(
			{
				"kind": "reaction",
				"source": 5,
				"cell": b.units[5].cell,
				"ability": "command",
				"text":
				"REAÇÃO — Comando das Cinzas: acólitos fortalecidos; não é um turno adicional."
			}
		)
		for i in range(6, b.units.size()):
			if b.units[i].hp > 0:
				b.apply_status(i, "attack", 1)
	else:
		var cell: Vector2i = b.units[target].cell
		var power: int = (
			b.Config.REACTION_PHASE_TWO_DAMAGE if b.boss_phase == 2 else b.Config.REACTION_DAMAGE
		)
		b.record(
			{
				"kind": "reaction",
				"source": 5,
				"cell": cell,
				"ability": "warning",
				"text": "REAÇÃO — Brasa iminente. Responda: manter, defender ou evadir."
			}
		)
		var centers: Array[Vector2i] = [cell]
		b.prepare_meteors(centers, 0, power)
