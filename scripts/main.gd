extends Node2D
const Battle = preload("res://scripts/combat/battle.gd")
const Arena = preload("res://scripts/world/arena.gd")
const HybridArena = preload("res://scripts/camera/hybrid_arena.gd")
const Hud = preload("res://scripts/ui/battle_hud.gd")
const VictorySequence = preload("res://scripts/visuals/victory_sequence.gd")
@export var use_tactical_camera := true
var battle := Battle.new()
var arena: Arena
var hud := Hud.new()
var victory := VictorySequence.new()
var selected := 1
var shown_turn_index := 1
var enemy_action_finished := false
var mode := "move"
var busy := false
var meteor_ui_active := false
var status := "Seu turno: mova, use ação e bônus. Espaço encerra · R reinicia."


func _ready() -> void:
	if arena == null:
		arena = (
			HybridArena.new()
			if use_tactical_camera and "--original-2d" not in OS.get_cmdline_user_args()
			else Arena.new()
		)
	arena.battle = battle
	arena.cinematic_victory = true
	add_child(arena)
	add_child(hud)
	add_child(victory)
	victory.configure(arena, battle)
	_connect_arena_signals()
	hud.hero_selected.connect(_select)
	hud.mode_selected.connect(_set_mode)
	hud.skill_selected.connect(_choose_skill)
	hud.end_requested.connect(_end_round)
	hud.restart_requested.connect(_restart)
	hud.meteor_choice.connect(_meteor_choice)
	_refresh()


func _select(index: int) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
		return
	if (
		index >= 0
		and index < 5
		and battle.units[index].hp > 0
		and battle.player_visible(index)
		and battle.outcome.is_empty()
	):
		selected = index
		mode = "move"
		_refresh()


func _set_mode(value: String) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
		return
	mode = value
	_refresh()


func _choose_skill(id: String) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
		return
	mode = id
	var skill := Battle.Abilities.get_skill(id)
	if skill.get("target", "") == "self":
		_execute(id, battle.units[selected].cell)
	else:
		status = "Selecione um alvo para " + skill.get("name", id) + "."
		_refresh()


func _execute(id: String, cell: Vector2i) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
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
	if battle.meteor_window:
		if mode == "meteor_evade":
			_respond_meteor("evade", cell)
		return
	if not battle.outcome.is_empty():
		return
	var target := battle.unit_at(cell)
	if target >= 0 and not battle.player_visible(target):
		target = -1
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
	if busy or not battle.outcome.is_empty():
		return
	if battle.meteor_window:
		_respond_meteor("stay")
		return
	if battle.active_index >= 5:
		return
	arena.capture_state()
	status = battle.end_turn()
	enemy_action_finished = false
	arena.present(battle.events)
	_refresh()
	if not busy:
		_continue_turns.call_deferred()


func _continue_turns() -> void:
	if busy or not battle.outcome.is_empty():
		return
	if _handle_meteor_window():
		return
	if battle.active_index < 5:
		return
	arena.capture_state()
	if not enemy_action_finished:
		battle.events.clear()
		enemy_action_finished = true
		battle.act_enemy()
		status = "O combatente inimigo executa seu turno."
	else:
		enemy_action_finished = false
		status = battle.end_turn()
	arena.present(battle.events)
	_refresh()
	if not busy:
		_continue_turns.call_deferred()


func _restart() -> void:
	busy = false
	meteor_ui_active = false
	victory.reset()
	battle = Battle.new()
	victory.configure(arena, battle)
	arena.battle = battle
	arena.reset_visuals()
	selected = battle.active_index
	shown_turn_index = battle.active_index
	enemy_action_finished = false
	mode = "move"
	status = "Batalha reiniciada: HP, mana, estados, recargas e invocações restaurados."
	_refresh()


func _refresh() -> void:
	if busy:
		hud.lock_interface()
		return
	if meteor_ui_active and not battle.meteor_window:
		selected = battle.active_index if battle.active_index < 5 else battle.observer_index()
		mode = "move"
	meteor_ui_active = battle.meteor_window
	if battle.meteor_window and battle.response_index >= 0:
		selected = battle.response_index
	elif shown_turn_index != battle.active_index:
		shown_turn_index = battle.active_index
		selected = battle.active_index if battle.active_index < 5 else battle.observer_index()
		mode = "move"
	arena.selected = selected
	arena.show_moves = mode == "move" and not battle.meteor_window
	arena.skill_id = "basic" if mode == "attack" else mode
	arena.queue_redraw()
	hud.refresh(battle, selected, mode, status)
	hud.inspect_target(battle, arena.hovered)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F2:
		_toggle_presentation()
		return
	if event.keycode == KEY_R:
		_restart()
		return
	if not battle.outcome.is_empty():
		if event.keycode == KEY_SPACE and victory.is_playing():
			victory.skip()
		return
	if battle.meteor_window:
		if event.keycode == KEY_SPACE:
			_end_round()
		elif event.keycode == KEY_E:
			_meteor_choice("evade")
		elif event.keycode == KEY_D:
			_meteor_choice("guard")
		elif event.keycode == KEY_ESCAPE and not busy:
			mode = "meteor_response"
			_refresh()
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		_select(event.keycode - KEY_1)
	elif event.keycode == KEY_SPACE:
		_end_round()
	elif event.keycode == KEY_A:
		_set_mode("attack")
	elif event.keycode in [KEY_Q, KEY_W, KEY_E, KEY_T] and not busy:
		var slot := [KEY_Q, KEY_W, KEY_E, KEY_T].find(event.keycode)
		if slot < hud.skill_ids.size():
			_choose_skill(hud.skill_ids[slot])
	elif event.keycode == KEY_ESCAPE:
		_set_mode("move")


func _on_presentation_started() -> void:
	busy = true
	hud.lock_interface()
	hud.sync_visibility(battle, selected)
	hud.message.text = "Ação em andamento… [R] reinicia a batalha."


func _on_presentation_finished() -> void:
	busy = false
	if battle.outcome == "BOSS DEFEATED":
		_refresh()
		if not victory.is_playing() and not victory.is_finished():
			victory.start()
		return
	if _handle_meteor_window():
		return
	_refresh()
	_continue_turns.call_deferred()


func _on_display_state_changed() -> void:
	hud.refresh_snapshot(battle, arena.visual_units, arena.visible_to_player, selected)


func _handle_meteor_window() -> bool:
	if not battle.meteor_window:
		return false
	if battle.response_index < 0:
		arena.capture_state()
		battle.events.clear()
		battle.resolve_meteor_window()
		arena.present(battle.events)
		_refresh()
		if not busy:
			_continue_turns.call_deferred()
		return true
	selected = battle.response_index
	mode = "meteor_response"
	status = "Meteoro iminente: escolha uma única resposta. O impacto ocorre após as respostas."
	_refresh()
	return true


func _meteor_choice(choice: String) -> void:
	if busy or not battle.meteor_window or battle.response_index < 0:
		return
	if choice == "evade":
		if battle.emergency_destinations(battle.response_index).is_empty():
			status = "Sem evasão válida: é preciso 1 ação e um pouso seguro em até 2 células."
		else:
			mode = "meteor_evade"
			status = "Clique num destino marcado: evasão consome 1 ação principal. Esc volta às opções."
		_refresh()
		return
	_respond_meteor(choice)


func _respond_meteor(choice: String, destination: Vector2i = Vector2i.ZERO) -> void:
	if busy or not battle.meteor_window or battle.response_index < 0:
		return
	var reason: String = battle.can_meteor_response(battle.response_index, choice, destination)
	if not reason.is_empty():
		status = reason
		_refresh()
		return
	arena.capture_state()
	battle.events.clear()
	if not battle.meteor_response(battle.response_index, choice, destination):
		status = battle.last_error
		_refresh()
		return
	mode = "meteor_response"
	status = "Resposta registrada. Sem turno extra ou renovação de recursos."
	arena.present(battle.events)
	_refresh()
	if not busy:
		_continue_turns.call_deferred()


func _connect_arena_signals() -> void:
	arena.cell_clicked.connect(_on_cell)
	arena.presentation_started.connect(_on_presentation_started)
	arena.presentation_finished.connect(_on_presentation_finished)
	arena.display_state_changed.connect(_on_display_state_changed)
	arena.cell_hovered.connect(
		func(cell: Vector2i):
			if not busy:
				hud.inspect_target(battle, cell)
	)


func _toggle_presentation() -> void:
	if busy or victory.is_playing():
		status = "Aguarde a ação terminar para alternar a apresentação."
		return
	var hybrid: bool = arena.has_method("world_cell")
	var previous_arena: Node2D = arena
	remove_child(previous_arena)
	previous_arena.queue_free()
	arena = Arena.new() if hybrid else HybridArena.new()
	arena.battle = battle
	arena.cinematic_victory = true
	add_child(arena)
	move_child(arena, 0)
	_connect_arena_signals()
	victory.configure(arena, battle)
	status = (
		"Apresentação original 2D. [F2] retorna à câmera tática."
		if hybrid
		else "Câmera tática 2.5D. [F2] retorna à apresentação original."
	)
	_refresh()
