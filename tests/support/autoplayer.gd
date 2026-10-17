# gdlint: disable=max-returns
extends RefCounted
## Políticas de teste, externas à IA de produção; não alteram HP, recursos ou RNG.
const POLICIES := [
	"agressivo",
	"defensivo",
	"cura",
	"antimagia",
	"lacaios",
	"ignora_lacaios",
	"mau_posicionamento",
	"evita_meteoros",
	"enfrenta_fumaca",
	"evasao_excessiva",
	"ignora_meteoros",
	"corpo_a_corpo"
]
var policy := "agressivo"
var casts := {}
var known_cells := {}


func play_hero(b: RefCounted, hero: int) -> void:
	if hero != b.active_index or b.units[hero].hp <= 0:
		return
	for enemy in range(5, b.units.size()):
		if b.can_observe(hero, enemy):
			known_cells[enemy] = b.units[enemy].cell
	if not known_cells.has(5):
		# Posição pública na abertura da batalha, sem rastrear movimento oculto.
		known_cells[5] = Vector2i(12, 4)
	var bonuses := [["giant", "hammer", "skin"], ["dodge"], [], ["flight"], ["illusion"]]
	if policy in ["defensivo", "cura"]:
		bonuses[0] = ["skin", "hammer", "giant"]
	for id in bonuses[hero]:
		if b.availability(hero, id).is_empty():
			use(b, hero, id, b.units[hero].cell)
			break
	if hero == 2:
		if policy in ["antimagia", "defensivo", "evita_meteoros"]:
			if (
				b.has_status(5, "fire_shield")
				and b.can_use(hero, "antispell", known_cells[5]).is_empty()
			):
				use(b, hero, "antispell", known_cells[5])
				return
			for zone in b.smoke:
				if b.can_use(hero, "antispell", zone.cell).is_empty():
					use(b, hero, "antispell", zone.cell)
					return
		var heal_threshold := 20 if policy in ["cura", "defensivo"] else 50
		if policy != "mau_posicionamento":
			var worst := -1
			var deficit := heal_threshold - 1
			for ally in 5:
				var missing: int = b.units[ally].max_hp - b.units[ally].hp
				if b.units[ally].hp > 0 and missing > deficit:
					if b.can_use(hero, "heal", b.units[ally].cell).is_empty():
						worst = ally
						deficit = missing
			if worst >= 0:
				use(b, hero, "heal", b.units[worst].cell)
				return
	var preferences := [
		["double", "basic"],
		["fushigiri", "unarmed", "basic"],
		["purple_fire", "basic"],
		["energy_arrow", "ice_arrow", "root_arrow", "basic"],
		["chain", "basic"]
	]
	if policy == "defensivo":
		preferences[4] = ["silence", "chain", "basic"]
	if policy == "enfrenta_fumaca":
		preferences[3] = ["ice_arrow", "energy_arrow", "root_arrow", "basic"]
	var chosen := "basic"
	for id in preferences[hero]:
		if b.availability(hero, id).is_empty():
			chosen = id
			break
	var target := 5
	if policy == "lacaios":
		var nearest := 999
		for enemy in range(6, b.units.size()):
			if b.units[enemy].hp > 0 and b.can_observe(hero, enemy):
				var d: int = b.distance(b.units[hero].cell, b.units[enemy].cell)
				if d < nearest:
					target = enemy
					nearest = d
	var target_cell: Vector2i = known_cells.get(target, known_cells[5])
	var destination: Vector2i = b.units[hero].cell
	var best_score := 99999
	var reachable: Dictionary = b.reachable(hero)
	var reach: int = b.skill_range(hero, chosen)
	for cell in reachable:
		var d: int = b.distance(cell, target_cell)
		var score: int = reachable[cell]
		if d > reach:
			score += 100 + d * 5
		if not b.visible(cell, target_cell) and chosen != "ice_arrow":
			score += 100
		if reach > 2 and d <= 1 and policy != "mau_posicionamento":
			score += 50
		if policy in ["mau_posicionamento", "corpo_a_corpo"]:
			score += d * 20
		if policy in ["evita_meteoros", "defensivo", "cura", "antimagia", "lacaios"]:
			for mark in b.meteors:
				if b.distance(cell, mark.cell) <= mark.radius:
					score += 250
		if policy in ["evita_meteoros", "defensivo", "cura", "antimagia", "lacaios"]:
			for zone in b.fire_zones:
				if zone.cell == cell:
					score += 150
		if score < best_score:
			best_score = score
			destination = cell
	b.move_unit(hero, destination)
	for enemy in range(5, b.units.size()):
		if b.can_observe(hero, enemy):
			known_cells[enemy] = b.units[enemy].cell
	target_cell = known_cells.get(target, known_cells[5])
	for id in preferences[hero]:
		if b.can_use(hero, id, target_cell).is_empty():
			use(b, hero, id, target_cell)
			return
	if policy == "ignora_lacaios":
		return
	for enemy in range(6, b.units.size()):
		if b.can_observe(hero, enemy) and b.can_use(hero, "basic", b.units[enemy].cell).is_empty():
			use(b, hero, "basic", b.units[enemy].cell)
			return


func respond_meteor(b: RefCounted) -> void:
	var hero: int = b.response_index
	if hero < 0:
		b.resolve_meteor_window()
		return
	var evade := (
		policy
		in ["evita_meteoros", "evasao_excessiva", "defensivo", "cura", "antimagia", "lacaios"]
	)
	# Defesa usa bônus/PM quando a política prefere preservar sua ação ofensiva.
	var prefer_guard := policy == "defensivo"
	prefer_guard = prefer_guard or (policy == "agressivo" and b.units[hero].mana >= 80)
	if policy == "evita_meteoros" and b.units[hero].hp >= 65 and b.can_observe(hero, 5):
		prefer_guard = b.distance(b.units[hero].cell, b.units[5].cell) <= b.units[hero].range
	if prefer_guard and b.can_meteor_response(hero, "guard", b.units[hero].cell).is_empty():
		b.meteor_response(hero, "guard", b.units[hero].cell)
		return
	if evade:
		var destinations: Dictionary = b.emergency_destinations(hero)
		var best := Vector2i(-1, -1)
		var score := 99999
		for cell in destinations:
			var danger: int = b.distance(cell, b.units[5].cell)
			# Usa somente o chefe observado; sem rastrear posição oculta.
			if not b.can_observe(hero, 5):
				danger = 0
			var value: int = int(destinations[cell]) * 10 - danger
			for zone in b.fire_zones:
				if zone.cell == cell:
					value += 200
			if value < score:
				score = value
				best = cell
		if best != Vector2i(-1, -1) and b.can_meteor_response(hero, "evade", best).is_empty():
			b.meteor_response(hero, "evade", best)
			return
	b.meteor_response(hero, "stay", b.units[hero].cell)


func use(b: RefCounted, hero: int, id: String, cell: Vector2i) -> void:
	if b.use_ability(hero, id, cell):
		casts[id] = int(casts.get(id, 0)) + 1
