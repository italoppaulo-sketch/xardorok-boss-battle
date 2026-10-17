extends CanvasLayer
signal hero_selected(index: int)
signal mode_selected(mode: String)
signal skill_selected(id: String)
signal end_requested
signal restart_requested
const Abilities = preload("res://scripts/data/abilities.gd")
const Statuses = preload("res://scripts/combat/statuses.gd")
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
var panel: PanelContainer


func _label(parent: Node, at: Vector2, size2d: Vector2, font_size: int = 15) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size2d
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e2dfd6"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _button(parent: Node, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.position = at
	button.size = dimensions
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	for kind in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("222b3b") if kind == "normal" else Color("35445b")
		if kind == "disabled":
			style.bg_color = Color("1c202b")
		style.border_color = Color("716a54") if kind == "hover" else Color("414858")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(kind, style)
	parent.add_child(button)
	return button


func _ready() -> void:
	var title := _label(self, Vector2(40, 20), Vector2(720, 38), 28)
	title.text = "XARDOROK  /  FOGO E CINZAS"
	summary = _label(self, Vector2(40, 63), Vector2(720, 42), 16)
	target_info = _label(self, Vector2(40, 104), Vector2(720, 22), 13)
	target_info.max_lines_visible = 1
	target_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel = PanelContainer.new()
	panel.position = Vector2(790, 18)
	panel.size = Vector2(388, 664)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141c2a")
	style.border_color = Color("817052")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	# Conteúdo livre para manter dimensões previsíveis na resolução de referência.
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	var heading := _label(content, Vector2(16, 12), Vector2(356, 26), 17)
	heading.text = "HERÓIS  ·  MARCO 3"
	for i in 5:
		var button := _button(content, Vector2(16 + i * 71, 46), Vector2(67, 48))
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(func(): hero_selected.emit(i))
		hero_buttons.append(button)
	info = _label(content, Vector2(16, 104), Vector2(356, 52))
	state_info = _label(content, Vector2(16, 158), Vector2(356, 40), 13)
	state_info.max_lines_visible = 2
	state_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for i in 2:
		var button := _button(content, Vector2(16 + i * 182, 204), Vector2(174, 34))
		button.text = "Mover" if i == 0 else "Ataque básico"
		var value := "move" if i == 0 else "attack"
		button.pressed.connect(func(): mode_selected.emit(value))
		action_buttons.append(button)
	for i in 4:
		var button := _button(content, Vector2(16, 246 + i * 43), Vector2(356, 38))
		button.pressed.connect(
			func():
				if i < skill_ids.size():
					skill_selected.emit(skill_ids[i])
		)
		skill_buttons.append(button)
	description = _label(content, Vector2(16, 424), Vector2(356, 112), 14)
	end_button = _button(content, Vector2(16, 548), Vector2(356, 40))
	end_button.text = "Encerrar rodada dos heróis [Espaço]"
	end_button.pressed.connect(func(): end_requested.emit())
	var restart := _button(content, Vector2(16, 602), Vector2(356, 34))
	restart.text = "Reiniciar batalha [R]"
	restart.pressed.connect(func(): restart_requested.emit())
	message = _label(self, Vector2(40, 582), Vector2(720, 108), 15)


func refresh(battle: RefCounted, selected: int, mode: String, status: String) -> void:
	var unit: Dictionary = battle.units[selected]
	summary.text = (
		("Rodada %d · Xardorok %d/%d HP · Lacaios %d\n" + "Ordem: grupo → Xardorok → lacaios")
		% [battle.round_number, battle.units[5].hp, battle.units[5].max_hp, battle.living_minions()]
	)
	for i in 5:
		var hero: Dictionary = battle.units[i]
		hero_buttons[i].text = "%s%s\n%d HP" % ["•" if i == selected else "", hero.name, hero.hp]
		hero_buttons[i].disabled = hero.hp <= 0 or not battle.outcome.is_empty()
		hero_buttons[i].tooltip_text = (
			"%s: %d/%d HP\n%s" % [hero.name, hero.hp, hero.max_hp, Statuses.describe(hero)]
		)
	info.text = (
		"%s   %d/%d HP   %d/%d PM\nPassos %d   Ação %d   Bônus %d"
		% [
			unit.name,
			unit.hp,
			unit.max_hp,
			unit.mana,
			unit.max_mana,
			unit.move,
			unit.actions,
			unit.bonus
		]
	)
	state_info.text = Statuses.describe(unit)
	state_info.tooltip_text = state_info.text
	action_buttons[0].disabled = (
		unit.hp <= 0
		or not battle.outcome.is_empty()
		or unit.move <= 0
		or battle.has_status(selected, "rooted")
		or battle.has_status(selected, "frozen")
	)
	action_buttons[1].disabled = not battle.availability(selected, "basic").is_empty()
	skill_ids = Abilities.loadout(selected)
	for i in 4:
		var button := skill_buttons[i]
		button.visible = i < skill_ids.size()
		if not button.visible:
			continue
		var id: String = skill_ids[i]
		var skill := Abilities.get_skill(id)
		var cost: String = "Bônus" if skill.get("bonus", false) else "Ação"
		var hp_cost: String = " · %d HP" % skill.hp_cost if skill.has("hp_cost") else ""
		var cd: int = unit.cooldowns.get(id, 0)
		button.text = (
			"%s%s\n%s · %d PM%s · alcance %d%s"
			% [
				"▶ " if mode == id else "",
				skill.name,
				cost,
				skill.get("mana", 0),
				hp_cost,
				battle.skill_range(selected, id),
				" · CD %d" % cd if cd > 0 else ""
			]
		)
		button.modulate = Color(skill.color).lerp(Color.WHITE, 0.6)
		var reason: String = battle.availability(selected, id)
		button.disabled = not reason.is_empty()
		button.tooltip_text = skill.description + ("\n" + reason if not reason.is_empty() else "")
	var selected_id := "basic" if mode == "attack" else mode
	if selected_id == "move":
		description.text = (
			"MOVER\nClique nos pontos azuis para andar. Pilares bloqueiam caminhos e visão. "
			+ "Voo cruza obstáculos, mas exige pouso livre."
		)
	else:
		var skill := Abilities.get_skill(selected_id)
		description.text = skill.get("name", "") + "\n" + skill.get("description", "")
		if skill.get("target", "") == "self":
			description.text += "\nAplicada ao escolher o botão."
	var recent: PackedStringArray = []
	var start: int = maxi(0, battle.history.size() - 2)
	for i in range(start, battle.history.size()):
		recent.append(battle.history[i])
	message.text = status + ("\n" + "\n".join(recent) if not recent.is_empty() else "")
	if not battle.outcome.is_empty():
		message.text = battle.outcome + "\nPressione R para jogar novamente."
	end_button.disabled = not battle.outcome.is_empty()


func inspect_target(battle: RefCounted, cell: Vector2i) -> void:
	var index: int = battle.unit_at(cell)
	if index < 0:
		target_info.text = "Selecione uma habilidade e clique no alvo. Antispell também aceita o chão."
	else:
		var unit: Dictionary = battle.units[index]
		target_info.text = (
			"%s · %d/%d HP · %s" % [unit.name, unit.hp, unit.max_hp, Statuses.describe(unit)]
		)

	target_info.tooltip_text = target_info.text


func lock_interface() -> void:
	for button in hero_buttons + action_buttons + skill_buttons:
		button.disabled = true
	end_button.disabled = true
