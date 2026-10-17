extends Node2D
const Battle = preload("res://scripts/combat/battle.gd")
const Arena = preload("res://scripts/world/arena.gd")
const Hud = preload("res://scripts/ui/battle_hud.gd")
var battle := Battle.new()
var arena := Arena.new()
var hud := Hud.new()
var selected := 0
var mode := "move"
var busy := false
var status := (
	"Escolha um herói (1–5), uma habilidade e seu alvo.\n"
	+ "Magias pessoais usam o bônus ao clicar no botão. Espaço encerra a rodada."
)


func _ready() -> void:
	arena.battle = battle
	add_child(arena)
	add_child(hud)
	arena.cell_clicked.connect(_on_cell)
	arena.presentation_started.connect(_on_presentation_started)
	arena.presentation_finished.connect(_on_presentation_finished)
	arena.cell_hovered.connect(
		func(cell: Vector2i):
			if not busy:
				hud.inspect_target(battle, cell)
	)
	hud.hero_selected.connect(_select)
	hud.mode_selected.connect(_set_mode)
	hud.skill_selected.connect(_choose_skill)
	hud.end_requested.connect(_end_round)
	hud.restart_requested.connect(_restart)
	_refresh()


func _select(index: int) -> void:
	if busy:
		return
	if index >= 0 and index < 5 and battle.units[index].hp > 0 and battle.outcome.is_empty():
		selected = index
		mode = "move"
		_refresh()


func _set_mode(value: String) -> void:
	if busy:
		return
	mode = value
	_refresh()


func _choose_skill(id: String) -> void:
	if busy:
		return
	mode = id
	var skill := Battle.Abilities.get_skill(id)
	if skill.get("target", "") == "self":
		_execute(id, battle.units[selected].cell)
	else:
		status = "Selecione um alvo para " + skill.get("name", id) + "."
		_refresh()


func _execute(id: String, cell: Vector2i) -> void:
	if busy:
		return
	arena.capture_state()
	battle.events.clear()
	var success := battle.use_ability(selected, id, cell)
	status = "Habilidade executada." if success else battle.last_error
	arena.present(battle.events)
	_refresh()


func _on_cell(cell: Vector2i) -> void:
	if busy:
		return
	if not battle.outcome.is_empty():
		return
	var target := battle.unit_at(cell)
	var id := "basic" if mode == "attack" else mode
	var skill := Battle.Abilities.get_skill(id)
	if target >= 0 and target < 5 and skill.get("target", "") not in ["ally", "ground", "self"]:
		_select(target)
		return
	if mode == "move":
		arena.capture_state()
		battle.events.clear()
		status = (
			"Movimento realizado."
			if battle.move_unit(selected, cell)
			else "Destino bloqueado, estado impeditivo ou movimento insuficiente."
		)
		arena.present(battle.events)
		_refresh()
	else:
		_execute(id, cell)


func _end_round() -> void:
	if busy:
		return
	arena.capture_state()
	status = battle.enemy_turn()
	arena.present(battle.events)
	if battle.units[selected].hp <= 0:
		for i in 5:
			if battle.units[i].hp > 0:
				selected = i
				break
	mode = "move"
	_refresh()


func _restart() -> void:
	busy = false
	battle = Battle.new()
	arena.battle = battle
	arena.reset_visuals()
	selected = 0
	mode = "move"
	status = "Batalha reiniciada: HP, mana, estados, recargas e invocações restaurados."
	_refresh()


func _refresh() -> void:
	if busy:
		hud.lock_interface()
		return
	arena.selected = selected
	arena.show_moves = mode == "move"
	arena.skill_id = "basic" if mode == "attack" else mode
	arena.queue_redraw()
	hud.refresh(battle, selected, mode, status)
	hud.inspect_target(battle, arena.hovered)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		_select(event.keycode - KEY_1)
	elif event.keycode == KEY_SPACE:
		_end_round()
	elif event.keycode == KEY_R:
		_restart()
	elif event.keycode == KEY_ESCAPE:
		_set_mode("move")


func _on_presentation_started() -> void:
	busy = true
	hud.lock_interface()
	hud.message.text = "Ação em andamento… [R] reinicia a batalha."


func _on_presentation_finished() -> void:
	busy = false
	_refresh()
