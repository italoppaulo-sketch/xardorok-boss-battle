extends RefCounted
## Regras sem dependência de interface. A grade interna não é desenhada.
const Roster = preload("res://scripts/data/roster.gd")
const SIZE := Vector2i(15, 9)
const WALLS := [Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 5), Vector2i(7, 6)]
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var units: Array[Dictionary] = Roster.create_units()
var round_number := 1
var outcome := ""


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
	var start: Vector2i = units[index].cell
	var costs := {start: 0}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if not inside(next) or next in WALLS or costs.has(next) or unit_at(next) != -1:
				continue
			var cost: int = costs[cell] + 1
			if cost <= units[index].move:
				costs[next] = cost
				pending.append(next)
	return costs


func move_unit(index: int, destination: Vector2i) -> bool:
	if not outcome.is_empty() or units[index].hp <= 0:
		return false
	var costs := reachable(index)
	if not costs.has(destination) or destination == units[index].cell:
		return false
	units[index].move -= costs[destination]
	units[index].cell = destination
	return true


func visible(a: Vector2i, b: Vector2i) -> bool:
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
	if not outcome.is_empty() or attacker < 0 or target < 0:
		return false
	var source: Dictionary = units[attacker]
	var victim: Dictionary = units[target]
	if source.hp <= 0 or victim.hp <= 0 or source.enemy == victim.enemy or source.actions <= 0:
		return false
	if distance(source.cell, victim.cell) > source.range or not visible(source.cell, victim.cell):
		return false
	source.actions -= 1
	victim.hp = maxi(0, victim.hp - source.damage)
	check_outcome()
	return true


func check_outcome() -> void:
	if units[5].hp <= 0:
		outcome = "BOSS DEFEATED"
		return
	for unit in units:
		if not unit.enemy and unit.hp > 0:
			return
	outcome = "GRUPO DERROTADO"


func enemy_turn() -> String:
	if not outcome.is_empty():
		return outcome
	var boss: Dictionary = units[5]
	boss.move = 4
	boss.actions = 1
	var target := -1
	var nearest := 999
	for i in 5:
		if units[i].hp > 0:
			var d := distance(boss.cell, units[i].cell)
			if d < nearest:
				nearest = d
				target = i
	if target < 0:
		check_outcome()
		return outcome
	var best: Vector2i = boss.cell
	var costs := reachable(5)
	for cell in costs:
		if distance(cell, units[target].cell) < distance(best, units[target].cell):
			best = cell
	move_unit(5, best)
	var message := "Xardorok avança."
	if attack(5, target):
		message = "Xardorok atinge %s: %d de dano." % [units[target].name, boss.damage]
	if outcome.is_empty():
		round_number += 1
		for unit in units:
			unit.move = 5
			unit.actions = 1
	return message
