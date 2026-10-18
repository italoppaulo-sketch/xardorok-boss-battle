extends SceneTree
const Battle = preload("res://scripts/combat/battle.gd")
const Strategy = preload("res://tests/support/smoke_capture_strategy.gd")


func _initialize() -> void:
	var reports := []
	var failures := 0
	for conservative in [false, true]:
		var b := Battle.new()
		b.rng.seed = 42
		var bot := Strategy.new()
		bot.conservative = conservative
		var smoke_casts := 0
		for step in 1600:
			if not b.outcome.is_empty():
				break
			b.events.clear()
			if b.meteor_window:
				bot.respond_meteor(b)
				continue
			else:
				if b.active_index >= 5:
					b.act_enemy()
				else:
					bot.play_hero(b, b.active_index)
			for event in b.events:
				if event.kind == "cast" and event.get("ability") == "smoke":
					smoke_casts += 1
			if not b.meteor_window and b.outcome.is_empty():
				b.end_turn()
		var attacks_in_smoke := []
		var illegal_los := []
		for entry in bot.audit:
			if entry.executed and entry.offensive:
				if entry.smoke_count > 0:
					attacks_in_smoke.append(entry)
				if not entry.visible and entry.ability != "ice_arrow":
					illegal_los.append(entry)
		if conservative:
			if not attacks_in_smoke.is_empty() or not illegal_los.is_empty():
				failures += 1
			if smoke_casts == 0 or bot.dispelled_clouds == 0:
				failures += 1
			if b.outcome != "BOSS DEFEATED":
				failures += 1
		reports.append(
			{
				"conservative": conservative,
				"outcome": b.outcome,
				"rounds": b.round_number,
				"smoke_casts": smoke_casts,
				"held_attacks": bot.held_attacks,
				"dispelled_clouds": bot.dispelled_clouds,
				"attacks_in_smoke": attacks_in_smoke,
				"illegal_los": illegal_los
			}
		)
	var file := FileAccess.open("res://docs/audio/smoke_policy_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "reports": reports}, "\t"))
	print(JSON.stringify({"failures": failures, "reports": reports}))
	quit(1 if failures else 0)
