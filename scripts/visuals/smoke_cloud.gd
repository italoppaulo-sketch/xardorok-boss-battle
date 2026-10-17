extends Node2D
## Volume animado sobre o mundo; a ocultação das unidades vem de Perception.
var arena: Node2D
var texture: Texture2D
var clock := 0.0
var births := {}
var fading: Array[Dictionary] = []
var previous := {}


func _ready() -> void:
	z_index = 25
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = load("res://assets/effects/smoke/atlas.png")


func reset() -> void:
	births.clear()
	fading.clear()
	previous.clear()


func _process(delta: float) -> void:
	clock += delta
	var current := {}
	for zone in arena.visual_smoke:
		var key := "%s:%s" % [zone.cell, zone.expires]
		current[key] = zone
		if not births.has(key):
			births[key] = clock
	for key in previous:
		if not current.has(key):
			fading.append({"zone": previous[key], "start": clock})
			births.erase(key)
	previous = current
	for effect in fading.duplicate():
		if clock - effect.start > 0.6:
			fading.erase(effect)
	queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	for key in previous:
		_cloud(previous[key], clampf((clock - births[key]) * 2.5, 0.1, 1), 1)
	for effect in fading:
		_cloud(effect.zone, 1 + (clock - effect.start) * 0.35, 1 - (clock - effect.start) / 0.6)


func _cloud(zone: Dictionary, growth: float, opacity: float) -> void:
	var center: Vector2 = arena.center(zone.cell)
	var radius: float = zone.radius * arena.TILE * growth
	# Displaced overlapping puffs supply volume and an irregular rolling silhouette.
	for ring in 2:
		var count := 9 if ring == 0 else 6
		for i in count:
			var angle := i * TAU / count + sin(clock * 0.35 + i) * 0.09
			var distance := radius * (0.53 if ring == 0 else 0.23)
			var point := center + Vector2(cos(angle), sin(angle) * 0.86) * distance
			point += Vector2(sin(clock + i * 3), cos(clock * 0.7 + i)) * 5
			var diameter := radius * (1.04 if ring == 0 else 1.15)
			var frame := (int(clock * 4) + i + ring) % 4
			draw_texture_rect_region(
				texture,
				Rect2(point - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter),
				Rect2(frame * 96, 0, 96, 96),
				Color(0.32, 0.33, 0.39, opacity * (0.8 if ring == 0 else 0.9))
			)
	for i in 18:
		var point := (
			center + Vector2(sin(i * 4.7 + clock * 0.3), cos(i * 3.1 + clock * 0.2)) * radius * 0.8
		)
		draw_rect(Rect2(point, Vector2(2, 2)), Color(0.64, 0.56, 0.48, opacity * 0.32))
