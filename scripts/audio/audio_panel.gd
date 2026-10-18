extends CanvasLayer
## Independent fixed HUD panel; no combat controls or camera transforms are changed.
var audio: Node
var panel := PanelContainer.new()
var button := Button.new()
var sliders := {}
var mutes := {}


func _ready() -> void:
	layer = 85
	button.text = "Áudio [F10]"
	button.position = Vector2(1064, 108)
	button.size = Vector2(124, 28)
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	button.pressed.connect(toggle)
	panel.position = Vector2(790, 145)
	panel.custom_minimum_size = Vector2(398, 350)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141921fa")
	style.border_color = Color("c8ad72")
	style.set_border_width_all(2)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	panel.add_child(rows)
	var title := Label.new()
	title.text = "ÁUDIO · volumes independentes"
	rows.add_child(title)
	for bus in audio.settings:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var label := Label.new()
		label.text = {
			"Master": "Geral",
			"Music": "Música",
			"SFX": "Efeitos",
			"Ambience": "Ambiência",
			"UI": "Interface"
		}[bus]
		label.custom_minimum_size.x = 80
		row.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(165, 28)
		slider.min_value = 0
		slider.max_value = 100
		slider.value = audio.settings[bus] * 100
		row.add_child(slider)
		slider.value_changed.connect(func(value: float): audio.set_volume(bus, value / 100))
		sliders[bus] = slider
		var mute := Button.new()
		mute.toggle_mode = true
		mute.custom_minimum_size = Vector2(80, 28)
		mute.text = "Mudo" if audio.muted.get(bus, false) else "Ligado"
		mute.button_pressed = audio.muted.get(bus, false)
		row.add_child(mute)
		mute.toggled.connect(
			func(value: bool):
				audio.set_mute(bus, value)
				mute.text = "Mudo" if value else "Ligado"
		)
		mutes[bus] = mute
	var hint := Label.new()
	hint.text = "M: mudo geral · F10: abrir/fechar\nPreferências preservadas ao reiniciar."
	hint.add_theme_font_size_override("font_size", 12)
	rows.add_child(hint)
	var close := Button.new()
	close.text = "Fechar"
	rows.add_child(close)
	close.pressed.connect(toggle)
	panel.hide()


func toggle() -> void:
	panel.visible = not panel.visible
	audio.ui("ui_open")


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F10:
		toggle()
	elif event.keycode == KEY_M:
		var value: bool = not audio.muted.get("Master", false)
		audio.set_mute("Master", value)
		mutes.Master.set_pressed_no_signal(value)
		mutes.Master.text = "Mudo" if value else "Ligado"
	else:
		return
	get_viewport().set_input_as_handled()
