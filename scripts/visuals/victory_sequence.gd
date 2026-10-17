extends CanvasLayer
## Encenação local da vitória. Nunca altera turnos, HP ou Engine.time_scale.
signal finished
var arena: Node2D
var battle: RefCounted
var elapsed := 0.0
var playing := false
var completed := false
var canvas := Control.new()
var shade := ColorRect.new()
var band := ColorRect.new()
var title := Label.new()
var subtitle := Label.new()
var crown := TextureRect.new()
var crown_origin := Vector2.ZERO
var duration := 3.6


func _ready() -> void:
	layer = 70
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.015, 0.01, 0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shade)
	band.position = Vector2(0, 246)
	band.size = Vector2(1200, 166)
	band.color = Color(0.025, 0.018, 0.01, 0.83)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(band)
	title.text = "REI DAS CINZAS DERROTADO"
	title.position = Vector2(40, 281)
	title.size = Vector2(1120, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 43)
	var serif := load("res://assets/ui/fonts/DejaVuSerif.ttf") as Font
	title.add_theme_font_override("font", serif)
	title.add_theme_color_override("font_color", Color("e6c879"))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.22, 0.04, 0.9))
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(title)
	subtitle.text = "A coroa cai. As cinzas encontram repouso.  [Espaço] pular · [R] reiniciar"
	subtitle.position = Vector2(200, 356)
	subtitle.size = Vector2(800, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("c4b696"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(subtitle)
	crown.texture = load("res://assets/environments/xardorok_arena/props/crown.png")
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.size = Vector2(36, 30)
	crown.pivot_offset = crown.size * 0.5
	crown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(crown)
	reset()


func configure(arena_node: Node2D, combat: RefCounted) -> void:
	arena = arena_node
	battle = combat


func start() -> void:
	if playing or completed or arena == null:
		return
	elapsed = 0
	playing = true
	canvas.visible = true
	var boss: Vector2 = arena.positions.get(5, arena.center(Vector2i(11, 4)))
	crown_origin = arena.to_global(boss) + Vector2(-18, -88)
	crown.position = crown_origin
	_update_visuals()


func skip() -> void:
	if playing:
		elapsed = duration
		_update_visuals()
		_complete()


func reset() -> void:
	playing = false
	completed = false
	elapsed = 0
	canvas.visible = false


func is_playing() -> bool:
	return playing


func is_finished() -> bool:
	return completed


func _process(delta: float) -> void:
	if not playing:
		return
	elapsed += delta
	_update_visuals()
	if elapsed >= duration:
		_complete()


func _update_visuals() -> void:
	# A caída usa PNG da própria coroa; os personagens continuam sendo seus sprites.
	var fall := clampf((elapsed - 0.15) / 0.85, 0, 1)
	var bounce := absf(sin(fall * PI * 2.5)) * (1 - fall) * 13
	if arena.has_method("crown_screen_at"):
		crown.position = arena.crown_screen_at(fall, bounce)
	else:
		crown.position = crown_origin + Vector2(fall * 25, fall * fall * 80 - bounce)
	crown.rotation = fall * 0.62
	crown.modulate.a = clampf(elapsed * 4, 0, 1)
	shade.color.a = clampf((elapsed - 0.6) * 0.24, 0, 0.36)
	var reveal := clampf((elapsed - 1.05) / 0.65, 0, 1)
	band.modulate.a = reveal
	title.modulate.a = reveal
	subtitle.modulate.a = clampf((elapsed - 1.5) * 2, 0, 1)
	title.scale = Vector2.ONE * lerpf(1.025, 1.0, reveal)
	if arena != null and arena.actors.has(5):
		var actor: Node2D = arena.actors[5]
		# Apenas o relógio da animação final desacelera; nenhuma regra fica lenta.
		actor.sprite.speed_scale = 0.65 if elapsed < 0.7 else 1.0
		actor.modulate.a = lerpf(1.0, 0.7, clampf((elapsed - 1) / 2, 0, 1))


func _complete() -> void:
	playing = false
	completed = true
	if arena != null and arena.actors.has(5):
		arena.actors[5].sprite.speed_scale = 1.0
	finished.emit()
