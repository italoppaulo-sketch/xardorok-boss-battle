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
	for id in ["floor_0", "floor_1", "floor_crack", "floor_cold"]:
		floor_textures.append(load(BASE + id + ".png"))
	floor_cells = Geometry.floor_cells()
	for cell in floor_cells:
		if cell not in blocked:
			walkable_cells.append(cell)
	for i in blocked.size():
		var cell: Vector2i = blocked[i]
		var rubble := _prop("ruin_%d" % (i % 4), _center(cell) + Vector2(0, 14), 0.9)
		rubble.set_meta("blocked_cell", cell)
	# Architectural flanks remain outside the movement surface; no central columns.
	_prop("arch_0", Vector2(origin.x - 88, origin.y + 350), 1.45)
	_prop("arch_3", Vector2(origin.x + tile * 15 + 88, origin.y + 350), 1.45)
	_prop("arch_1", Vector2(origin.x - 120, origin.y + 125), 0.95)
	_prop("arch_2", Vector2(origin.x + tile * 15 + 120, origin.y + 125), 0.95)
	# The braziers include their own load-bearing stone pedestals.
	for point in [Vector2(292, 146), Vector2(908, 146), Vector2(292, 551), Vector2(908, 551)]:
		var brazier := _prop("brazier", point)
		braziers.append(brazier)
		_light(point + Vector2(0, -34), Color("ffae63"), 0.3)
	# Ice emerges from rock fractures in the cold, broken perimeter.
	_prop("ice_fissure", Vector2(348, 129), 0.85)
	_prop("ice_fissure", Vector2(855, 552), 0.75)
	_light(Vector2(350, 123), Color("8ebde4"), 0.17)
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
	draw_texture_rect(backdrop, Rect2(0, 94, 1200, 480), false, Color(0.72, 0.76, 0.84))
	# Cloud sprites drift in the abyss before the physical arena is drawn.
	for i in 4:
		var drift := sin(time * 0.055 + i) * 28.0
		draw_texture_rect(
			cloud,
			Rect2(i * 350.0 - 100 + drift, 355 + i % 2 * 70, 460, 240),
			false,
			Color(0.63, 0.71, 0.8, 0.2)
		)
	# Each exposed southern edge receives a vertical masonry face. Its top begins
	# exactly where the final walkable tile ends; no unsupported extra surface.
	for cell in floor_cells:
		if not Geometry.valid_cell(cell + Vector2i.DOWN):
			var point := origin + Vector2(cell + Vector2i.DOWN) * tile
			draw_texture_rect(
				fascia, Rect2(point, Vector2(tile, 27)), false, Color(0.45, 0.48, 0.55)
			)
	for cell in floor_cells:
		var id := 0 if (cell.x + cell.y * 3) % 5 else 1
		if cell in [Vector2i(2, 3), Vector2i(12, 5), Vector2i(6, 7)]:
			id = 2
		if cell in [Vector2i(4, 0), Vector2i(10, 8)]:
			id = 3
		var point := origin + Vector2(cell) * tile
		var shade := 0.70 + 0.035 * sin(cell.x * 0.7 + cell.y * 0.4)
		draw_texture_rect(
			floor_textures[id],
			Rect2(point, Vector2.ONE * tile),
			false,
			Color(shade, shade * 0.98, shade * 0.98)
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
