extends Node2D
## O desenho do piso usa exatamente a geometria recebida do combate.
const BASE := "res://assets/environments/xardorok_arena/"
var origin := Vector2(40, 130)
var tile := 48.0
var map_size := Vector2i(15, 9)
var blocked: Array = []
var walkable_cells: Array[Vector2i] = []
var floor_textures: Array[Texture2D] = []
var backdrop: Texture2D
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
	backdrop = load(BASE + "backgrounds/castle_distance.png")
	for id in ["floor_0", "floor_1", "floor_2", "floor_crack"]:
		floor_textures.append(load(BASE + "tiles/" + id + ".png"))
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			if cell not in blocked:
				walkable_cells.append(cell)
	for cell in walls:
		_prop("pillar", origin + (Vector2(cell) + Vector2(0.5, 0.5)) * tile + Vector2(0, 20))
	# Todos estes pés ficam fora do retângulo caminhável.
	for point in [Vector2(20, 175), Vector2(780, 175), Vector2(20, 550), Vector2(780, 550)]:
		var brazier := _prop("brazier_0", point, 0.65)
		braziers.append(brazier)
		_light(point + Vector2(0, -20), Color("ffb063"), 0.22)
	_prop("crystals", Vector2(17, 420), 0.55)
	_prop("crystals_small", Vector2(782, 400), 0.6)
	_prop("throne", Vector2(678, 124), 0.85)
	_prop("chain", Vector2(53, 123), 0.6)
	_prop("chain", Vector2(750, 123), 0.6)
	_light(Vector2(25, 385), Color("a2d6ff"), 0.15)


func _prop(id: String, feet: Vector2, size_scale: float = 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = id.capitalize() + str(props.size())
	sprite.texture = load(BASE + "props/" + id + ".png")
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
	for i in braziers.size():
		var frame := (int(time * 7) + i) % 4
		braziers[i].texture = load(BASE + "props/brazier_%d.png" % frame)
	queue_redraw()


func _draw() -> void:
	if backdrop == null:
		return
	# Camada distante acima e ao redor do piso, sem plataforma pintada ao fundo.
	draw_texture_rect(backdrop, Rect2(31, 0, 738, 306), false, Color(0.8, 0.85, 1))
	draw_rect(Rect2(33, 123, 734, 446), Color("171c2a"))
	for y in map_size.y:
		for x in map_size.x:
			var floor_id: int = (x * 7 + y * 11) % floor_textures.size()
			var point := origin + Vector2(x, y) * tile
			draw_texture_rect(
				floor_textures[floor_id],
				Rect2(point, Vector2.ONE * tile),
				false,
				Color(0.82, 0.85, 0.94)
			)
	# Moldura e detalhes externos não mudam a área caminhável.
	draw_rect(
		Rect2(origin - Vector2(4, 4), Vector2(map_size) * tile + Vector2(8, 8)),
		Color("717184"),
		false,
		3
	)
	for i in 24:
		var point := (
			origin + Vector2(fmod(i * 83.0 + time * 4, 720), fmod(i * 47.0 - time * 8 + 432, 432))
		)
		draw_rect(Rect2(point, Vector2.ONE * (1 if i % 2 else 2)), Color(0.8, 0.7, 0.6, 0.13))
