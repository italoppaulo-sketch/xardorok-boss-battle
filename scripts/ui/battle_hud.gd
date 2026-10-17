extends CanvasLayer
## Original bronze/obsidian tactical HUD. All costs and commands come from the combat model.
signal hero_selected(index: int)
signal mode_selected(mode: String)
signal skill_selected(id: String)
signal end_requested
signal restart_requested
signal meteor_choice(choice: String)
const Abilities = preload("res://scripts/data/abilities.gd")
const Statuses = preload("res://scripts/combat/statuses.gd")
const InitiativeScene = preload("res://scenes/ui/initiative_bar.tscn")
const AbilityScene = preload("res://scenes/ui/ability_bar.tscn")
const PORTRAITS := ["grosso", "kodokami", "cassandra", "thomas", "thuxil", "xardorok", "lacaio"]
const GOLD := Color("c8ad72")
const INK := Color("11151b")
var summary: Label
var info: Label
var state_info: Label
var description: Label
var message: Label
var target_info: Label
var hero_buttons: Array[Button] = []
var action_buttons: Array[Button] = []
var skill_buttons: Array[Button] = []
var skill_ids: Array = []
var end_button: Button
var panel: Panel
var initiative_buttons: Array[Button] = []
var initiative_root: Control
var ability_root: Control
var hero_portrait: TextureRect
var hero_hp: ProgressBar
var hero_mana: ProgressBar
var boss_hp: ProgressBar
var boss_label: Label
var reaction_label: Label
var log_panel: Panel
var log_text: RichTextLabel
var log_button: Button
var turn_label: Label
var emergency_root: Control
var emergency_title: Label
var emergency_evade: Button
var emergency_guard: Button
var boss_state_icons: Array[TextureRect] = []
var _portrait_cache: Dictionary = {}
var _icon_cache: Dictionary = {}


func _style(fill: Color, border: Color, thickness: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(4)
	return style


func _panel(at: Vector2, dimensions: Vector2) -> Panel:
	var result := Panel.new()
	result.position = at
	result.size = dimensions
	result.add_theme_stylebox_override("panel", _style(Color("11151bf2"), Color("776346")))
	add_child(result)
	return result


func _label(parent: Node, at: Vector2, dimensions: Vector2, font_size: int = 14) -> Label:
	var result := Label.new()
	result.position = at
	result.size = dimensions
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color("e8e0cd"))
	result.add_theme_color_override("font_shadow_color", Color("080b10"))
	result.add_theme_constant_override("shadow_offset_y", 1)
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(result)
	return result


func _button(parent: Node, at: Vector2, dimensions: Vector2) -> Button:
	var result := Button.new()
	result.position = at
	result.size = dimensions
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_size_override("font_size", 13)
	result.add_theme_color_override("font_color", Color("e8e0cd"))
	result.add_theme_color_override("font_disabled_color", Color("7f817e"))
	result.add_theme_stylebox_override("normal", _style(Color("1b222a"), Color("63563f")))
	result.add_theme_stylebox_override("hover", _style(Color("303741"), GOLD, 2))
	result.add_theme_stylebox_override("pressed", _style(Color("464133"), GOLD, 2))
	result.add_theme_stylebox_override("disabled", _style(Color("15191f"), Color("343936")))
	parent.add_child(result)
	return result


func _picture(parent: Node, at: Vector2, dimensions: Vector2) -> TextureRect:
	var result := TextureRect.new()
	result.position = at
	result.size = dimensions
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


func _bar(parent: Node, at: Vector2, dimensions: Vector2, color: Color) -> ProgressBar:
	var result := ProgressBar.new()
	result.position = at
	result.show_percentage = false
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("background", _style(Color("080c12"), Color("514733")))
	result.add_theme_stylebox_override("fill", _style(color, color.lightened(.15), 0))
	parent.add_child(result)
	result.size = dimensions
	return result


func _portrait(index: int) -> Texture2D:
	var identity: String = PORTRAITS[mini(index, 6)]
	if not _portrait_cache.has(identity):
		_portrait_cache[identity] = load("res://assets/ui/portraits/%s.png" % identity)
	return _portrait_cache[identity]


func _icon(id: String) -> Texture2D:
	if not _icon_cache.has(id):
		var path := "res://assets/ui/ability_icons/%s.png" % id
		_icon_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _icon_cache[id]


func _ready() -> void:
	layer = 10
	_panel(Vector2(12, 6), Vector2(1176, 70))
	summary = _label(self, Vector2(24, 12), Vector2(160, 23), 16)
	turn_label = _label(self, Vector2(24, 36), Vector2(160, 31), 12)
	turn_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	turn_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	initiative_root = InitiativeScene.instantiate()
	add_child(initiative_root)
	for i in 5:
		_ensure_initiative_button(i)
	_panel(Vector2(332, 79), Vector2(536, 22))
	boss_hp = _bar(self, Vector2(334, 81), Vector2(532, 18), Color("922f27"))
	boss_label = _label(self, Vector2(340, 80), Vector2(520, 20), 12)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reaction_label = _label(self, Vector2(883, 80), Vector2(303, 23), 12)
	reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for i in 2:
		var state_icon := _picture(self, Vector2(880 + i * 32, 105), Vector2(26, 26))
		state_icon.mouse_filter = Control.MOUSE_FILTER_PASS
		state_icon.hide()
		boss_state_icons.append(state_icon)
	target_info = _label(self, Vector2(330, 103), Vector2(540, 23), 12)
	target_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel = _panel(Vector2(12, 566), Vector2(280, 126))
	hero_portrait = _picture(self, Vector2(20, 580), Vector2(82, 82))
	info = _label(self, Vector2(109, 573), Vector2(174, 55), 13)
	info.autowrap_mode = TextServer.AUTOWRAP_OFF
	hero_hp = _bar(self, Vector2(110, 632), Vector2(166, 8), Color("a64943"))
	hero_mana = _bar(self, Vector2(110, 645), Vector2(166, 6), Color("4f9cb6"))
	state_info = _label(self, Vector2(23, 666), Vector2(255, 18), 11)
	_panel(Vector2(302, 566), Vector2(686, 126))
	ability_root = AbilityScene.instantiate()
	add_child(ability_root)
	var heading := _label(ability_root, Vector2(316, 571), Vector2(650, 19), 11)
	heading.text = "MOVIMENTO     /     AÇÃO PRINCIPAL     /     AÇÃO BÔNUS"
	heading.modulate = GOLD
	for i in 2:
		var button := _ability_button(Vector2(316 + i * 94, 592))
		var value := "move" if i == 0 else "attack"
		button.pressed.connect(func(): mode_selected.emit(value))
		action_buttons.append(button)
	for i in 4:
		var button := _ability_button(Vector2(504 + i * 116, 592), 108)
		button.pressed.connect(
			func():
				if i < skill_ids.size():
					skill_selected.emit(skill_ids[i])
		)
		skill_buttons.append(button)
	emergency_root = Control.new()
	emergency_root.name = "MeteorResponses"
	add_child(emergency_root)
	emergency_root.hide()
	emergency_title = _label(emergency_root, Vector2(316, 571), Vector2(650, 23), 12)
	emergency_title.modulate = GOLD
	emergency_evade = _button(emergency_root, Vector2(316, 600), Vector2(308, 62))
	emergency_evade.text = "EVASÃO EMERGENCIAL [E]\n1 ação · até 2 células · escolha o destino"
	emergency_evade.pressed.connect(func(): meteor_choice.emit("evade"))
	emergency_guard = _button(emergency_root, Vector2(638, 600), Vector2(334, 62))
	emergency_guard.text = "DEFENDER-SE [D]\n1 bônus + 8 PM · 50% menos dano do impacto"
	emergency_guard.pressed.connect(func(): meteor_choice.emit("guard"))
	description = _label(self, Vector2(316, 676), Vector2(658, 14), 10)
	_panel(Vector2(998, 566), Vector2(190, 126))
	end_button = _button(self, Vector2(1008, 576), Vector2(170, 43))
	end_button.text = "ENCERRAR TURNO\n[Espaço]"
	end_button.pressed.connect(func(): end_requested.emit())
	log_button = _button(self, Vector2(1008, 624), Vector2(170, 25))
	log_button.text = "Registro de combate"
	log_button.pressed.connect(func(): log_panel.visible = not log_panel.visible)
	var restart := _button(self, Vector2(1008, 654), Vector2(170, 26))
	restart.text = "Reiniciar [R]"
	restart.pressed.connect(func(): restart_requested.emit())
	message = _label(self, Vector2(230, 542), Vector2(740, 21), 12)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_panel = _panel(Vector2(796, 315), Vector2(392, 241))
	log_panel.visible = false
	var log_title := _label(log_panel, Vector2(12, 8), Vector2(330, 20), 13)
	log_title.text = "REGISTRO DA BATALHA"
	var close := _button(log_panel, Vector2(352, 7), Vector2(28, 25))
	close.text = "×"
	close.pressed.connect(func(): log_panel.hide())
	log_text = RichTextLabel.new()
	log_text.position = Vector2(12, 38)
	log_text.size = Vector2(368, 190)
	log_text.add_theme_font_size_override("normal_font_size", 12)
	log_text.scroll_following = true
	log_panel.add_child(log_text)


func _ability_button(at: Vector2, width: int = 86) -> Button:
	var button := _button(ability_root, at, Vector2(width, 80))
	var glyph := _picture(button, Vector2((width - 40) / 2.0, 3), Vector2(40, 40))
	glyph.name = "Glyph"
	var title := _label(button, Vector2(2, 43), Vector2(width - 4, 17), 11)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cost := _label(button, Vector2(2, 61), Vector2(width - 4, 15), 10)
	cost.name = "Cost"
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button


func _ensure_initiative_button(index: int) -> void:
	while initiative_buttons.size() <= index:
		var unit_index := initiative_buttons.size()
		var button := _button(initiative_root, Vector2.ZERO, Vector2(68, 60))
		var face := _picture(button, Vector2(14, 1), Vector2(40, 40))
		face.name = "Portrait"
		var name_label := _label(button, Vector2(2, 41), Vector2(64, 17), 10)
		name_label.name = "Name"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var badges := _label(button, Vector2(39, 2), Vector2(26, 16), 10)
		badges.name = "States"
		badges.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badges.modulate = GOLD
		button.pressed.connect(
			func():
				if unit_index < 5:
					hero_selected.emit(unit_index)
		)
		initiative_buttons.append(button)
		if unit_index < 5:
			hero_buttons.append(button)


func _set_skill_button(
	button: Button, battle: RefCounted, index: int, id: String, selected_id: String
) -> void:
	var skill := Abilities.get_skill(id)
	var unit: Dictionary = battle.units[index]
	var cooldown: int = unit.cooldowns.get(id, 0)
	var reason: String = battle.availability(index, id)
	var action := "Bônus" if skill.get("bonus", false) else "Ação"
	var hp_cost: String = " · %d HP" % skill.hp_cost if skill.has("hp_cost") else ""
	var range_value: int = battle.skill_range(index, id)
	var name_value: String = skill.name
	if id == "basic":
		name_value = ["Martelo", "Punho", "Raio arcano", "Flecha", "Raio azul", "Espada", "Golpe"][mini(
			index, 6
		)]
	button.get_node("Title").text = name_value
	button.get_node("Cost").text = (
		"Recarga %d" % cooldown
		if cooldown > 0
		else "%s · %d PM%s" % [action, skill.get("mana", 0), hp_cost]
	)
	button.get_node("Glyph").texture = _icon("basic_%d" % mini(index, 6) if id == "basic" else id)
	button.tooltip_text = (
		"%s\n%s · %d PM%s · alcance %d · recarga %d\n%s%s"
		% [
			skill.name,
			action,
			skill.get("mana", 0),
			hp_cost,
			range_value,
			skill.get("cooldown", 0),
			skill.description,
			"\n" + reason if not reason.is_empty() else ""
		]
	)
	button.disabled = not reason.is_empty() or index != battle.active_index
	button.get_node("Glyph").modulate = Color("72777d") if button.disabled else Color.WHITE
	button.add_theme_stylebox_override(
		"normal",
		_style(
			Color("242b30"),
			GOLD if id == selected_id else Color(skill.color).darkened(.5),
			2 if id == selected_id else 1
		)
	)


func refresh(battle: RefCounted, selected: int, mode: String, status: String) -> void:
	var unit: Dictionary = battle.units[selected]
	var active: int = battle.active_index
	var active_unit: Dictionary = battle.units[active] if active >= 0 else {}
	var known_active: bool = active >= 0 and battle.player_visible(active)
	summary.text = "RODADA %02d" % battle.round_number
	turn_label.text = "Turno: " + (str(active_unit.name) if known_active else "combatente oculto")
	var order: Array = battle.initiative
	var active_slot: int = order.find(active)
	for offset in range(1, order.size() + 1):
		var next_index: int = order[(active_slot + offset) % order.size()]
		if battle.units[next_index].hp > 0:
			turn_label.text += (
				"\nPróximo: "
				+ (
					str(battle.units[next_index].name)
					if battle.player_visible(next_index)
					else "oculto"
				)
			)
			break
	var card_width: int = mini(68, int(974.0 / maxi(order.size(), 1)) - 4)
	for button in initiative_buttons:
		button.hide()
	for index in battle.units.size():
		_ensure_initiative_button(index)
		initiative_buttons[index].hide()
	for slot in order.size():
		var index: int = order[slot]
		var current: Dictionary = battle.units[index]
		var button := initiative_buttons[index]
		var visible_unit: bool = battle.player_visible(index)
		button.show()
		button.position = Vector2(196 + slot * (card_width + 4), 11)
		button.size = Vector2(card_width, 60)
		button.get_node("Portrait").position.x = (card_width - 40) / 2.0
		button.get_node("Portrait").texture = _portrait(index) if visible_unit else null
		button.get_node("Portrait").modulate = Color.WHITE if current.hp > 0 else Color("656970")
		button.get_node("Name").size.x = card_width - 4
		var badges: PackedStringArray = []
		for state in [
			"silenced",
			"frozen",
			"burning",
			"rooted",
			"flight",
			"illusion",
			"fire_shield",
			"fire_aura"
		]:
			if visible_unit and current.statuses.has(state):
				badges.append(
					{
						"silenced": "S",
						"frozen": "G",
						"burning": "Q",
						"rooted": "E",
						"flight": "V",
						"illusion": "I",
						"fire_shield": "P",
						"fire_aura": "F"
					}[state]
				)
		button.get_node("States").text = "".join(badges).left(3) if visible_unit else "?"
		button.get_node("States").position.x = card_width - 29
		button.get_node("Name").text = (
			("▶ " if index == active else "") + (str(current.name) if visible_unit else "Oculto")
		)
		button.disabled = (
			index >= 5 or not visible_unit or current.hp <= 0 or not battle.outcome.is_empty()
		)
		button.tooltip_text = (
			(
				"%s · iniciativa %d\n%s\n%s"
				% [
					current.name,
					current.initiative,
					"DERROTADO" if current.hp <= 0 else "%d/%d HP" % [current.hp, current.max_hp],
					Statuses.describe(current)
				]
			)
			if visible_unit
			else "Combatente oculto: posição e estado desconhecidos."
		)
		var edge := (
			GOLD
			if index == active or index == 5
			else (Color("5b9aaa") if index < 5 else Color("a04c3e"))
		)
		button.add_theme_stylebox_override(
			"normal",
			_style(
				Color("322d22") if index == active else INK,
				edge,
				2 if index == active or index == 5 else 1
			)
		)
		button.add_theme_stylebox_override(
			"disabled", _style(INK, edge, 2 if index == active or index == 5 else 1)
		)
	var boss: Dictionary = battle.units[5]
	var boss_visible: bool = battle.player_visible(5)
	boss_hp.visible = boss_visible
	boss_hp.max_value = boss.max_hp
	boss_hp.value = boss.hp if boss_visible else 0
	boss_label.text = (
		(
			"XARDOROK · %s · %d / %d HP"
			% [
				"O REI DAS CINZAS" if battle.boss_phase == 1 else "A IRA DO REI",
				boss.hp,
				boss.max_hp
			]
		)
		if boss_visible
		else "XARDOROK · OCULTO PELA FUMAÇA"
	)
	reaction_label.text = (
		"REAÇÕES  %d / %d   ·   FASE %d"
		% [battle.reactions_used, battle.Config.REACTIONS_PER_ROUND, battle.boss_phase]
	)
	_update_boss_states(boss, boss_visible)
	var visible_selected: bool = battle.player_visible(selected)
	ability_root.visible = visible_selected
	description.visible = visible_selected
	hero_portrait.texture = _portrait(selected) if visible_selected else null
	if visible_selected:
		info.text = (
			"%s%s\nHP %d / %d\nPM %d / %d"
			% [
				unit.name,
				" · ATIVO" if selected == active else " · INSPECIONAR",
				unit.hp,
				unit.max_hp,
				unit.mana,
				unit.max_mana
			]
		)
		hero_hp.max_value = unit.max_hp
		hero_hp.value = unit.hp
		hero_mana.max_value = maxi(1, unit.max_mana)
		hero_mana.value = unit.mana
		state_info.text = (
			"Ação %d · Bônus %d · Passos %d  |  %s"
			% [unit.actions, unit.bonus, unit.move, Statuses.describe(unit)]
		)
		state_info.tooltip_text = state_info.text
	else:
		info.text = "ALIADO OCULTO\nSem visão válida."
		state_info.text = "Posição e estado não observáveis."
		state_info.tooltip_text = state_info.text
	panel.tooltip_text = state_info.text
	hero_hp.visible = visible_selected
	hero_mana.visible = visible_selected
	var selected_id := "basic" if mode == "attack" else mode
	action_buttons[0].get_node("Title").text = "Mover [Esc]"
	action_buttons[0].get_node("Cost").text = "%d passos" % unit.move if visible_selected else "—"
	action_buttons[0].get_node("Glyph").texture = _icon("move")
	action_buttons[0].tooltip_text = (
		"Movimento\nEscolha uma célula válida. " + "Voo atravessa ruínas, mas exige pouso livre."
	)
	action_buttons[0].disabled = (
		selected != active
		or unit.hp <= 0
		or not battle.outcome.is_empty()
		or unit.move <= 0
		or battle.has_status(selected, "rooted")
		or battle.has_status(selected, "frozen")
	)
	_set_skill_button(action_buttons[1], battle, selected, "basic", selected_id)
	skill_ids = Abilities.loadout(selected)
	for i in skill_buttons.size():
		var button := skill_buttons[i]
		button.visible = i < skill_ids.size()
		if button.visible:
			_set_skill_button(button, battle, selected, skill_ids[i], selected_id)
	if selected_id == "move":
		description.text = (
			"Clique no piso marcado para mover. "
			+ "Retratos 1–5 inspecionam os heróis; apenas o ativo pode agir."
		)
	else:
		var skill := Abilities.get_skill(selected_id)
		description.text = skill.get("name", "") + " · " + skill.get("description", "")
	description.tooltip_text = description.text
	message.text = status.replace("\n", " · ")
	if not battle.outcome.is_empty():
		message.text = battle.outcome + " · Pressione R para jogar novamente."
	end_button.disabled = not battle.outcome.is_empty() or active < 0 or active >= 5
	end_button.text = "ENCERRAR TURNO\n[Espaço]"
	emergency_root.hide()
	if battle.meteor_window:
		_refresh_meteor_response(battle, mode)
	log_text.text = "\n".join(battle.player_history())
	log_button.text = "Registro de combate  ▴" if log_panel.visible else "Registro de combate  ▾"


func inspect_target(battle: RefCounted, cell: Vector2i) -> void:
	var floor_note := ""
	if battle.has_method("is_burning_cell") and battle.is_burning_cell(cell):
		floor_note = "CHÃO EM CHAMAS · risco ao entrar ou encerrar o turno. "
	elif "fires" in battle:
		for fire in battle.fires:
			if fire.get("cell", Vector2i(-1, -1)) == cell or cell in fire.get("cells", []):
				floor_note = "CHÃO EM CHAMAS · risco ao entrar ou encerrar o turno. "
				break
	var index: int = battle.unit_at(cell)
	if index < 0 or not battle.player_visible(index):
		target_info.text = floor_note
		target_info.tooltip_text = floor_note
		var observer: int = battle.observer_index()
		for known in battle.units.size():
			if (
				known != observer
				and not battle.player_visible(known)
				and battle.last_seen(observer, known) == cell
			):
				target_info.text = "Última posição observada · pode estar vazia; sem alvo visível."
				target_info.tooltip_text = (
					"Memória desatualizada. Áreas podem mirar o chão; "
					+ "ataques diretos exigem visão."
				)
				break
		return
	var unit: Dictionary = battle.units[index]
	target_info.text = (
		floor_note
		+ "%s · %d/%d HP · %s" % [unit.name, unit.hp, unit.max_hp, Statuses.describe(unit)]
	)
	target_info.tooltip_text = target_info.text
	if index == 5:
		target_info.tooltip_text += (
			"\nArmadura de cinzas: reduz dano final em 28%. Resistências: "
			+ "físico 30%; sombra/raio 20%; violeta 15%; fogo 45%; gelo -25%."
		)


func lock_interface() -> void:
	for button in hero_buttons + action_buttons + skill_buttons:
		button.disabled = true
	end_button.disabled = true
	emergency_evade.disabled = true
	emergency_guard.disabled = true


func sync_visibility(battle: RefCounted, selected: int) -> void:
	# During presentation, hide forbidden data without showing future HP.
	for index in initiative_buttons.size():
		if index >= battle.units.size() or battle.player_visible(index):
			continue
		var button := initiative_buttons[index]
		button.get_node("Portrait").texture = null
		button.get_node("Name").text = "Oculto"
		button.get_node("States").text = ""
		button.tooltip_text = "Combatente oculto: posição e estado desconhecidos."
	if not battle.player_visible(5):
		boss_hp.hide()
		boss_label.text = "XARDOROK · OCULTO"
	if not battle.player_visible(selected):
		hero_portrait.texture = null
		hero_hp.hide()
		hero_mana.hide()
		info.text = "ALIADO OCULTO"
		state_info.text = "Sem visão válida."
		ability_root.hide()
		description.hide()
	target_info.text = ""
	target_info.tooltip_text = ""


func refresh_snapshot(
	battle: RefCounted, units: Array[Dictionary], observed: Callable, selected: int
) -> void:
	if units.size() < 6:
		return
	var boss: Dictionary = units[5]
	var visible_boss: bool = observed.call(5)
	_update_boss_states(boss, visible_boss)
	boss_hp.visible = visible_boss
	boss_hp.max_value = boss.max_hp
	boss_hp.value = boss.hp if visible_boss else 0
	boss_label.text = (
		(
			"XARDOROK · %s · %d / %d HP"
			% [
				"A IRA DO REI" if boss.get("boss_phase", 1) == 2 else "O REI DAS CINZAS",
				boss.hp,
				boss.max_hp
			]
		)
		if visible_boss
		else "XARDOROK · OCULTO"
	)
	reaction_label.text = (
		"REAÇÕES %d / %d · FASE %d"
		% [battle.reactions_used, battle.Config.REACTIONS_PER_ROUND, boss.get("boss_phase", 1)]
	)
	if observed.call(selected):
		var unit: Dictionary = units[selected]
		hero_hp.value = unit.hp
		info.text = (
			"%s%s\nHP %d/%d\nPM %d/%d"
			% [
				unit.name,
				" · ATIVO" if selected == battle.active_index else " · INSPECIONAR",
				unit.hp,
				unit.max_hp,
				unit.mana,
				unit.max_mana
			]
		)


func _update_boss_states(boss: Dictionary, visible_boss: bool) -> void:
	var ids := ["fire_shield", "fire_aura"]
	for i in ids.size():
		var id: String = ids[i]
		var glyph := boss_state_icons[i]
		glyph.visible = visible_boss and boss.statuses.has(id)
		if glyph.visible:
			glyph.texture = _icon(id)
			var ability := Abilities.get_skill(id)
			glyph.tooltip_text = (
				"%s · %d turnos próprios restantes\n%s"
				% [ability.get("name", id), boss.statuses[id], ability.get("description", "")]
			)


func _refresh_meteor_response(battle: RefCounted, mode: String) -> void:
	ability_root.hide()
	emergency_root.show()
	description.show()
	lock_interface()
	var index: int = battle.response_index
	if index < 0:
		emergency_title.text = "IMPACTO IMINENTE · resolvendo áreas marcadas"
		end_button.text = "AGUARDE O IMPACTO"
		return
	var unit: Dictionary = battle.units[index]
	var threatened := PackedStringArray()
	if battle.has_method("meteor_responses"):
		for hero in battle.meteor_responses():
			threatened.append(str(battle.units[hero].name))
	emergency_title.text = "METEORO · RESPOSTA DE %s" % str(unit.name).to_upper()
	emergency_title.tooltip_text = (
		"Ameaçados: %s. Um comando por herói; depois todos os impactos são resolvidos."
		% ", ".join(threatened)
	)
	hero_portrait.texture = _portrait(index)
	hero_hp.show()
	hero_mana.show()
	hero_hp.max_value = unit.max_hp
	hero_hp.value = unit.hp
	hero_mana.max_value = maxi(1, unit.max_mana)
	hero_mana.value = unit.mana
	info.text = (
		"%s · REAÇÃO\nHP %d/%d\nPM %d/%d"
		% [unit.name, unit.hp, unit.max_hp, unit.mana, unit.max_mana]
	)
	state_info.text = (
		"Ação %d · Bônus %d · %s" % [unit.actions, unit.bonus, Statuses.describe(unit)]
	)
	state_info.tooltip_text = (
		"Recursos atuais, sem renovação. "
		+ "Fora do turno, evasão reserva a ação principal do próximo turno."
	)
	var guard_reason: String = battle.can_meteor_response(index, "guard", Vector2i.ZERO)
	emergency_guard.disabled = not guard_reason.is_empty()
	emergency_guard.tooltip_text = (
		"Reduz em 50% somente este impacto; consome 1 bônus e 8 PM."
		+ ("\n" + guard_reason if not guard_reason.is_empty() else "")
	)
	emergency_evade.disabled = battle.emergency_destinations(index).is_empty()
	emergency_evade.tooltip_text = (
		"Consome 1 ação principal. Máximo de 2 células, pouso livre fora de todas as marcas; "
		+ "enraizamento e congelamento impedem a evasão. Não concede turno extra."
	)
	end_button.disabled = false
	end_button.text = "MANTER POSIÇÃO\n[Espaço] · sem custo"
	end_button.tooltip_text = (
		"Aceita o impacto se ainda estiver na área. "
		+ "Confirma uma resposta, sem encerrar o turno normal."
	)
	description.text = (
		"Selecione uma célula segura marcada."
		if mode == "meteor_evade"
		else "Uma resposta por ameaçado: manter, defender ou evadir. Impacto após a última resposta."
	)
	description.tooltip_text = (
		"Ameaçados: %s. Iniciativa normal pausada; nenhum herói recebe movimento ou ações extras."
		% ", ".join(threatened)
	)
	turn_label.text = "RESPOSTA AO METEORO\nImpacto após as respostas"
