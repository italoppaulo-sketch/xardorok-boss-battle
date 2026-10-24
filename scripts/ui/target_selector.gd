extends CanvasLayer
## A transient, screen-space list; eligibility remains owned by the battle controller.
signal target_chosen(index: int)
signal target_highlighted(index: int)
signal dismissed
const IDENTITIES := ["grosso", "kodokami", "cassandra", "thomas", "thuxil", "xardorok", "lacaio"]
var candidates: Array[int] = []
var cursor := 0
var panel: PanelContainer
var rows: VBoxContainer
var buttons: Array[Button] = []
var battle: RefCounted


func _ready() -> void:
	layer = 24
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("131a23f8")
	style.border_color = Color("c8ad72")
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	rows = VBoxContainer.new()
	panel.add_child(rows)
	panel.hide()


func is_open() -> bool:
	return is_instance_valid(panel) and panel.visible


func open_targets(model: RefCounted, indices: Array[int], screen_position: Vector2) -> void:
	close(false)
	battle = model
	for index in indices:
		if model.valid_unit(index) and model.units[index].hp > 0 and model.player_visible(index):
			candidates.append(index)
	if candidates.is_empty():
		return
	var title := Label.new()
	title.text = "ESCOLHA O ALVO · Tab / Enter · Esc"
	title.add_theme_font_size_override("font_size", 12)
	rows.add_child(title)
	for index in candidates:
		var unit: Dictionary = model.units[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(292, 44)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.icon = load("res://assets/ui/portraits/%s.png" % IDENTITIES[mini(index, 6)])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 36)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.text = (
			"%s · %s\n%d/%d HP"
			% [unit.name, "Inimigo" if unit.enemy else "Aliado", unit.hp, unit.max_hp]
		)
		button.pressed.connect(func(): _choose(index))
		button.mouse_entered.connect(func(): _highlight(candidates.find(index)))
		rows.add_child(button)
		buttons.append(button)
	panel.show()
	var dimensions := Vector2(312, 40 + candidates.size() * 48)
	panel.size = dimensions
	var viewport_size := get_viewport().get_visible_rect().size
	panel.position = screen_position.clamp(
		Vector2(8, 106), viewport_size - dimensions - Vector2(8, 8)
	)
	cursor = 0
	_highlight(cursor)


func cycle(direction: int = 1) -> void:
	if not is_open() or candidates.is_empty():
		return
	_highlight(posmod(cursor + direction, candidates.size()))


func confirm() -> void:
	if is_open() and not candidates.is_empty():
		_choose(candidates[cursor])


func _choose(index: int) -> void:
	# Recheck alive/visibility even if state changed while the list was open.
	if battle.valid_unit(index) and battle.units[index].hp > 0 and battle.player_visible(index):
		target_chosen.emit(index)
	close()


func _highlight(value: int) -> void:
	cursor = value
	for i in buttons.size():
		buttons[i].modulate = Color("fff0b5") if i == cursor else Color.WHITE
	target_highlighted.emit(candidates[cursor])


func close(notify: bool = true) -> void:
	if is_instance_valid(panel):
		panel.hide()
		for child in rows.get_children():
			rows.remove_child(child)
			child.queue_free()
	candidates.clear()
	buttons.clear()
	cursor = 0
	if notify:
		dismissed.emit()
