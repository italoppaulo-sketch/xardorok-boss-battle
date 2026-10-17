extends Node2D
## Camadas de tempestade, ruínas, piso e objetos compartilham a geometria do combate.
const Geometry := preload("res://scripts/combat/arena_geometry.gd")
const BASE := "res://assets/environments/xardorok_arena/marco4/"
var origin := Vector2(225, 104)
var tile := 50.0
var map_size := Geometry.SIZE
var blocked: Array = []
var walkable_cells: Array[Vector2i] = []
var floor_cells: Array[Vector2i] = []
var floor_textures: Array[Texture2D] = []
var backdrop: Texture2D
var fascia: Texture2D
var cloud: Texture2D
var props: Array[Sprite2D] = []
var braziers: Array[Sprite2D] = []
var time := 0.0
var sorted_root: Node2D
var fire_atlas: Texture2D
var burnt_floor: Texture2D
var fire_points: Array[Vector2] = []


func setup(
	size2d: Vector2i, walls: Array, floor_origin: Vector2, tile_size: float, sorting: Node2D
) -> void:
	origin = floor_origin
	tile = tile_size
	map_size = size2d
	blocked = walls.duplicate()
	sorted_root = sorting
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -10
	backdrop = load(BASE + "storm_distance.png")
	fascia = load(BASE + "fascia.png")
	cloud = load(BASE + "cloud.png")
	fire_atlas = load("res://assets/effects/marco5/floor_fire.png")
	burnt_floor = load("res://assets/effects/marco5/floors.png")
	for id in ["floor_0", "floor_1", "floor_crack"]:
		floor_textures.append(load(BASE + id + ".png"))
	floor_cells = Geometry.floor_cells()
	for cell in floor_cells:
		if cell not in blocked:
			walkable_cells.append(cell)
	for i in blocked.size():
		var cell: Vector2i = blocked[i]
		# Todos os suportes ocupam obstáculos já registrados na geometria.
		# Assim, não há pedestal invisível em célula navegável.
		var support := _prop("brazier", _center(cell) + Vector2(0, 12), 0.75)
		support.set_meta("blocked_cell", cell)
		braziers.append(support)
		_light(support.position + Vector2(0, -35), Color("ff8f3d"), 0.32)
	# Architectural flanks remain outside the movement surface; no central columns.
	_prop("arch_0", Vector2(origin.x - 88, origin.y + 350), 1.45)
	_prop("arch_3", Vector2(origin.x + tile * 15 + 88, origin.y + 350), 1.45)
	_prop("arch_1", Vector2(origin.x - 120, origin.y + 125), 0.95)
	_prop("arch_2", Vector2(origin.x + tile * 15 + 120, origin.y + 125), 0.95)
	# Ruínas externas ardem sem acrescentar colisão ou piso falso.
	fire_points = [
		Vector2(origin.x - 85, origin.y + 310), Vector2(origin.x + tile * 15 + 86, origin.y + 310)
	]
	for point in fire_points:
		_light(point + Vector2(0, -28), Color("ff733d"), 0.24)
	queue_redraw()


func _center(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile


func _prop(id: String, feet: Vector2, size_scale: float = 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = id.capitalize() + str(props.size())
	sprite.texture = load(BASE + id + ".png")
	sprite.offset.y = -sprite.texture.get_height() * 0.5
	sprite.position = feet
	sprite.scale = Vector2.ONE * size_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sorted_root.add_child(sprite)
	props.append(sprite)
	return sprite


func _light(point: Vector2, color: Color, energy: float) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 192
	texture.height = 192
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	var light := PointLight2D.new()
	light.texture = texture
	light.color = color
	light.energy = energy
	light.position = point
	add_child(light)


func _process(delta: float) -> void:
	time += delta
	# Restrained fire flicker on supported perimeter flames, without moving their feet.
	for i in braziers.size():
		braziers[i].modulate = Color(1, 0.96 + sin(time * 8 + i) * 0.04, 0.92, 1)
	queue_redraw()


func _draw() -> void:
	if backdrop == null:
		return
	# The backdrop contains only sky, distant ruins and abyss, never a fake floor.
	draw_texture_rect(backdrop, Rect2(0, 94, 1200, 480), false, Color(0.83, 0.66, 0.59))
	# Cloud sprites drift in the abyss before the physical arena is drawn.
	for i in 4:
		var drift := sin(time * 0.055 + i) * 28.0
		draw_texture_rect(
			cloud,
			Rect2(i * 350.0 - 100 + drift, 355 + i % 2 * 70, 460, 240),
			false,
			Color(0.71, 0.57, 0.49, 0.22)
		)
	# Each exposed southern edge receives a vertical masonry face. Its top begins
	# exactly where the final walkable tile ends; no unsupported extra surface.
	for cell in floor_cells:
		if not Geometry.valid_cell(cell + Vector2i.DOWN):
			var point := origin + Vector2(cell + Vector2i.DOWN) * tile
			draw_texture_rect(
				fascia, Rect2(point, Vector2(tile, 27)), false, Color(0.5, 0.41, 0.36)
			)
	for cell in floor_cells:
		var id := 0 if (cell.x + cell.y * 3) % 5 else 1
		if cell in [Vector2i(2, 3), Vector2i(12, 5), Vector2i(6, 7)]:
			id = 2
		var point := origin + Vector2(cell) * tile
		var shade := 0.70 + 0.035 * sin(cell.x * 0.7 + cell.y * 0.4)
		draw_texture_rect(
			floor_textures[id],
			Rect2(point, Vector2.ONE * tile),
			false,
			Color(shade, shade * 0.98, shade * 0.98)
		)
		if (cell.x * 7 + cell.y * 11) % 5 <= 1:
			var burnt_id := (cell.x * 3 + cell.y * 5) % 4
			draw_texture_rect_region(
				burnt_floor,
				Rect2(point, Vector2.ONE * tile),
				Rect2(burnt_id * 96, 0, 96, 96),
				Color(0.73, 0.66, 0.58)
			)
		# Fine external lip only on actual geometric boundaries.
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if Geometry.valid_cell(cell + direction):
				continue
			var a := point
			var b := point
			if direction == Vector2i.UP:
				b += Vector2(tile, 0)
			elif direction == Vector2i.DOWN:
				a += Vector2(0, tile)
				b += Vector2(tile, tile)
			elif direction == Vector2i.RIGHT:
				a += Vector2(tile, 0)
				b += Vector2(tile, tile)
			else:
				b += Vector2(0, tile)
			draw_line(a, b, Color("837b66"), 2)
	# A brief distant storm flash, confined behind the HUD and low opacity.
	var flash := maxf(0, 1 - absf(fmod(time, 13.0) - 0.16) * 11)
	if flash > 0:
		draw_rect(Rect2(0, 96, 1200, 458), Color(0.65, 0.76, 1, flash * 0.045))
	for i in 32:
		var point := Vector2(
			fmod(i * 73.0 + time * (4 + i % 3), 1200), 104 + fmod(i * 47.0 + 450 - time * 7, 450)
		)
		draw_rect(Rect2(point, Vector2.ONE * (1 + i % 2)), Color(0.85, 0.78, 0.67, 0.12))

	# Chamas nas ruínas são imagens animadas; partículas discretas sobem do foco.
	for point in fire_points:
		var frame := int(time * 8 + point.x) % 4
		draw_texture_rect_region(
			fire_atlas,
			Rect2(point + Vector2(-38, -64), Vector2(76, 80)),
			Rect2(frame * 96, 0, 96, 96),
			Color(1, 1, 1, 0.85)
		)
		for ember in 4:
			var rise := fmod(time * 0.6 + ember * 0.22, 1.0)
			draw_rect(
				Rect2(point + Vector2(sin(ember + time) * 20, -rise * 86), Vector2(2, 2)),
				Color(1, 0.55, 0.13, 1 - rise)
			)
	# O fogo sobre cada suporte permanece ancorado nos quatro obstáculos reais.
	for brazier in braziers:
		var frame := int(time * 8 + brazier.position.x) % 4
		var point := brazier.position + Vector2(0, -42)
		draw_texture_rect_region(
			fire_atlas,
			Rect2(point + Vector2(-22, -28), Vector2(44, 40)),
			Rect2(frame * 96, 0, 96, 96)
		)
