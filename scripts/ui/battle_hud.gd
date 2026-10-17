extends CanvasLayer
signal hero_selected(index: int)
signal mode_selected(mode: String)
signal end_requested
signal restart_requested
var summary: Label
var info: Label
var message: Label
var hero_buttons: Array[Button] = []
var action_buttons: Array[Button] = []


func _ready() -> void:
	var title := Label.new()
	title.position = Vector2(40, 24)
	title.text = "XARDOROK  /  SEGUNDA FORMA"
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	summary = Label.new()
	summary.position = Vector2(40, 68)
	add_child(summary)
	var panel := PanelContainer.new()
	panel.position = Vector2(794, 24)
	panel.size = Vector2(380, 626)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = "MARCO 1 · PROTÓTIPO JOGÁVEL"
	column.add_child(heading)
	for i in 5:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = 36
		button.pressed.connect(func(): hero_selected.emit(i))
		column.add_child(button)
		hero_buttons.append(button)
	info = Label.new()
	column.add_child(info)
	for entry in [["Mover", "move"], ["Ataque básico", "attack"]]:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.text = entry[0]
		button.pressed.connect(func(): mode_selected.emit(entry[1]))
		column.add_child(button)
		action_buttons.append(button)
	var end := Button.new()
	end.focus_mode = Control.FOCUS_NONE
	end.text = "Encerrar rodada dos heróis [Espaço]"
	end.pressed.connect(func(): end_requested.emit())
	column.add_child(end)
	var restart := Button.new()
	restart.focus_mode = Control.FOCUS_NONE
	restart.text = "Reiniciar batalha [R]"
	restart.pressed.connect(func(): restart_requested.emit())
	column.add_child(restart)
	message = Label.new()
	message.position = Vector2(40, 590)
	message.size = Vector2(720, 90)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(message)


func refresh(battle: RefCounted, selected: int, mode: String, status: String) -> void:
	var unit: Dictionary = battle.units[selected]
	summary.text = (
		"Rodada %d  •  Xardorok: %d / %d HP"
		% [battle.round_number, battle.units[5].hp, battle.units[5].max_hp]
	)
	for i in 5:
		var hero: Dictionary = battle.units[i]
		hero_buttons[i].text = (
			"%s%s   %d/%d HP" % ["▶ " if i == selected else "", hero.name, hero.hp, hero.max_hp]
		)
		hero_buttons[i].disabled = hero.hp <= 0 or not battle.outcome.is_empty()
	info.text = (
		"%s\nMovimento: %d | Ações: %d\nDano: %d | Alcance: %d\nModo: %s"
		% [
			unit.name,
			unit.move,
			unit.actions,
			unit.damage,
			unit.range,
			"Mover" if mode == "move" else "Ataque básico"
		]
	)
	for button in action_buttons:
		button.disabled = unit.hp <= 0 or not battle.outcome.is_empty()
	message.text = (
		status
		if battle.outcome.is_empty()
		else battle.outcome + "\nPressione R para jogar novamente."
	)
