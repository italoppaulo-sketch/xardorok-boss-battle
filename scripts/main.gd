extends Node2D
const Battle = preload("res://scripts/combat/battle.gd")
const Arena = preload("res://scripts/world/arena.gd")
const Hud = preload("res://scripts/ui/battle_hud.gd")
const TacticalZoom = preload("res://scripts/visuals/tactical_zoom.gd")
const TargetSelector = preload("res://scripts/ui/target_selector.gd")
const VictorySequence = preload("res://scripts/visuals/victory_sequence.gd")
const BattleAudio = preload("res://scripts/audio/battle_audio.gd")
const AudioPanel = preload("res://scripts/audio/audio_panel.gd")
var audio := BattleAudio.new()
var audio_panel := AudioPanel.new()
var battle := Battle.new()
var arena := Arena.new()
var hud := Hud.new()
var victory := VictorySequence.new()
var camera := TacticalZoom.new()
var target_selector := TargetSelector.new()
var highlighted_target := -1
var selected := 1
var shown_turn_index := 1
var enemy_action_finished := false
var mode := "move"
var busy := false
var meteor_ui_active := false
var status := "Seu turno: mova, use ação e bônus. Espaço encerra · R reinicia."


func _ready() -> void:
	arena.battle = battle
	arena.cinematic_victory = true
	add_child(arena)
	add_child(camera)
	add_child(target_selector)
	add_child(hud)
	add_child(victory)
	victory.configure(arena, battle)
	add_child(audio)
	audio.bind(arena, victory)
	audio_panel.audio = audio
	add_child(audio_panel)
	hud.log_button.pressed.connect(func(): audio.ui("ui_open"))
	arena.cell_clicked.connect(_on_cell)
	arena.unit_candidates_clicked.connect(_on_candidates)
	target_selector.target_chosen.connect(_confirm_target)
	target_selector.target_highlighted.connect(_highlight_target)
	target_selector.dismissed.connect(func(): _highlight_target(-1))
	arena.presentation_started.connect(_on_presentation_started)
	arena.presentation_finished.connect(_on_presentation_finished)
	arena.display_state_changed.connect(_on_display_state_changed)
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
		target_selector.close()
		selected = index
		audio.ui()
		mode = "move"
		_refresh()


func _set_mode(value: String) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
		return
	target_selector.close()
	mode = value
	audio.ui()
	_refresh()


func _choose_skill(id: String) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
		return
	target_selector.close()
	mode = id
	audio.ui()
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
	if not success:
		audio.ui("ui_invalid")
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
		if battle.events.is_empty():
			audio.ui("ui_invalid")
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
	audio.restart()
	busy = false
	meteor_ui_active = false
	target_selector.close()
	camera.reset_view()
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
	if target_selector.is_open() and (battle.meteor_window or not battle.outcome.is_empty()):
		target_selector.close()
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
	if _handle_view_key(event.keycode):
		return
	if event.keycode == KEY_R:
		_restart()
		return
	if not battle.outcome.is_empty():
		if event.keycode == KEY_SPACE and victory.is_playing():
			victory.skip()
		return
	if not busy and not battle.meteor_window and _handle_target_key(event):
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


func _handle_target_key(event: InputEventKey) -> bool:
	if event.keycode == KEY_TAB:
		if target_selector.is_open():
			target_selector.cycle(-1 if event.shift_pressed else 1)
		else:
			var eligible: Array[int] = []
			for index in battle.units.size():
				if _eligible_target(index):
					eligible.append(index)
			target_selector.open_targets(battle, eligible, Vector2(620, 180))
	elif target_selector.is_open():
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			target_selector.confirm()
		elif event.keycode == KEY_ESCAPE:
			target_selector.close()
	else:
		return false
	get_viewport().set_input_as_handled()
	return true


func _handle_view_key(keycode: int) -> bool:
	match keycode:
		KEY_HOME:
			camera.reset_view()
		KEY_F:
			if battle.valid_unit(selected) and battle.player_visible(selected):
				camera.focus_world(arena.to_global(arena.center(battle.units[selected].cell)))
		_:
			return false
	get_viewport().set_input_as_handled()
	return true


func _on_presentation_started() -> void:
	target_selector.close()
	busy = true
	hud.lock_interface()
	hud.sync_visibility(battle, selected)
	hud.message.text = "Ação em andamento… [R] reinicia a batalha."


func _on_presentation_finished() -> void:
	busy = false
	if battle.outcome == "GRUPO DERROTADO":
		audio.defeat()
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
	if not meteor_ui_active:
		audio.ui("ui_open")
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
			audio.ui("ui_invalid")
			status = (
				"Sem evasão válida: confira a Reação Defensiva, estados "
				+ "e o espaço seguro em até 2 células."
			)
		else:
			mode = "meteor_evade"
			var current_action: bool = (
				battle.response_index == battle.active_index
				and battle.units[battle.response_index].actions > 0
			)
			status = (
				"Pouso seguro até 2 células: 1 Reação Defensiva; perde %s. Esc volta."
				% ("a ação atual" if current_action else "exatamente a próxima ação")
			)
		_refresh()
		return
	_respond_meteor(choice)


func _respond_meteor(choice: String, destination: Vector2i = Vector2i.ZERO) -> void:
	if busy or not battle.meteor_window or battle.response_index < 0:
		return
	var reason: String = battle.can_meteor_response(battle.response_index, choice, destination)
	if not reason.is_empty():
		audio.ui("ui_invalid")
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


func _eligible_target(index: int) -> bool:
	if (
		not battle.valid_unit(index)
		or battle.units[index].hp <= 0
		or not battle.player_visible(index)
	):
		return false
	if mode == "move":
		return true
	var id := "basic" if mode == "attack" else mode
	var skill := Battle.Abilities.get_skill(id)
	if skill.get("target", "") not in ["enemy", "ally"]:
		return false
	return battle.can_use(selected, id, battle.units[index].cell).is_empty()


func _on_candidates(indices: Array[int], screen_position: Vector2) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty():
		return
	var id := "basic" if mode == "attack" else mode
	if Battle.Abilities.get_skill(id).get("target", "") == "ground":
		var pointer: Vector2 = (
			arena.get_global_transform_with_canvas().affine_inverse() * screen_position
		)
		var grid: Vector2 = (pointer - arena.ORIGIN) / arena.TILE
		_on_cell(Vector2i(floori(grid.x), floori(grid.y)))
		return
	var eligible: Array[int] = []
	for index in indices:
		if _eligible_target(index):
			eligible.append(index)
	if eligible.size() == 1:
		_confirm_target(eligible[0])
	elif not eligible.is_empty():
		target_selector.open_targets(battle, eligible, screen_position)


func _confirm_target(index: int) -> void:
	if busy or battle.meteor_window or not battle.outcome.is_empty() or not _eligible_target(index):
		return
	if mode == "move" and index >= 5:
		hud.inspect_target(battle, battle.units[index].cell)
		status = (
			"Alvo observado: %s. Selecione uma habilidade para atacar." % battle.units[index].name
		)
		hud.message.text = status
		return
	_on_cell(battle.units[index].cell)


func _highlight_target(index: int) -> void:
	if index >= 0 and index != highlighted_target:
		audio.ui()
	highlighted_target = index
	arena.target_highlight = index
	if index >= 0 and battle.valid_unit(index) and battle.player_visible(index):
		hud.inspect_target(battle, battle.units[index].cell)
	arena.queue_redraw()
