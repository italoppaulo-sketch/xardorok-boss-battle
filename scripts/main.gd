extends Node2D
const Battle = preload("res://scripts/combat/battle.gd")
const Arena = preload("res://scripts/world/arena.gd")
const Hud = preload("res://scripts/ui/battle_hud.gd")
var battle := Battle.new()
var arena := Arena.new()
var hud := Hud.new()
var selected := 0
var mode := "move"
var status := (
	"Selecione um herói (botões ou 1–5). Clique no chão para mover; "
	+ "escolha Ataque básico e clique no chefe.\n"
	+ "Cada herói tem 5 passos e 1 ataque por rodada. Espaço: turno de Xardorok."
)


func _ready() -> void:
	arena.battle = battle
	add_child(arena)
	add_child(hud)
	arena.cell_clicked.connect(_on_cell)
	hud.hero_selected.connect(_select)
	hud.mode_selected.connect(_set_mode)
	hud.end_requested.connect(_end_round)
	hud.restart_requested.connect(_restart)
	_refresh()


func _select(index: int) -> void:
	if battle.units[index].hp > 0 and battle.outcome.is_empty():
		selected = index
		_refresh()


func _set_mode(value: String) -> void:
	mode = value
	_refresh()


func _on_cell(cell: Vector2i) -> void:
	if not battle.outcome.is_empty():
		return
	var target := battle.unit_at(cell)
	if target >= 0 and not battle.units[target].enemy:
		_select(target)
		return
	if mode == "move":
		status = (
			"Movimento realizado."
			if battle.move_unit(selected, cell)
			else "Destino bloqueado ou movimento insuficiente."
		)
	elif battle.attack(selected, target):
		status = (
			"%s atinge Xardorok: %d de dano."
			% [battle.units[selected].name, battle.units[selected].damage]
		)
	else:
		status = "Ataque inválido: verifique alvo, alcance, obstáculos e ações restantes."
	_refresh()


func _end_round() -> void:
	status = battle.enemy_turn()
	if battle.units[selected].hp <= 0:
		for i in 5:
			if battle.units[i].hp > 0:
				selected = i
				break
	_refresh()


func _restart() -> void:
	battle = Battle.new()
	arena.battle = battle
	selected = 0
	mode = "move"
	status = "Batalha reiniciada. Escolha um herói e avance pela arena."
	_refresh()


func _refresh() -> void:
	arena.selected = selected
	arena.show_moves = mode == "move"
	arena.queue_redraw()
	hud.refresh(battle, selected, mode, status)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		_select(event.keycode - KEY_1)
	elif event.keycode == KEY_SPACE:
		_end_round()
	elif event.keycode == KEY_R:
		_restart()
