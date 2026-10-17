extends RefCounted
## Pure presentation: deterministic continuous mask from the authoritative burning cells.
## The user photograph uses continuous world UVs, never reset at cell boundaries.
const ROCK_PATH := "res://assets/effects/marco51/volcanic_reference.png"
const PIXELS_PER_CELL := 32
var seed_value := 5107
var size := Vector2i(15, 9)
var rock_texture: Texture2D
var mask_texture: ImageTexture
var mask_image: Image
var cells := {}
var _signature := ""


func _init(grid_size := Vector2i(15, 9), fixed_seed := 5107) -> void:
	size = grid_size
	seed_value = fixed_seed
	rock_texture = load(ROCK_PATH)
	update_zones([])


func update_zones(zones: Array, walls: Array = []) -> bool:
	var next_cells := {}
	for zone in zones:
		var cell: Vector2i = zone.cell
		if (
			cell.x >= 0
			and cell.y >= 0
			and cell.x < size.x
			and cell.y < size.y
			and not walls.has(cell)
		):
			next_cells[cell] = true
	var ordered := next_cells.keys()
	ordered.sort_custom(
		func(a: Vector2i, b: Vector2i): return a.y * size.x + a.x < b.y * size.x + b.x
	)
	var signature := str(ordered)
	if signature == _signature and mask_texture != null:
		return false
	_signature = signature
	cells = next_cells
	mask_image = Image.create(
		size.x * PIXELS_PER_CELL, size.y * PIXELS_PER_CELL, false, Image.FORMAT_L8
	)
	mask_image.fill(Color.BLACK)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.6
	noise.fractal_octaves = 3
	for key in cells:
		var cell: Vector2i = key
		var exposed: Array[Vector2i] = []
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var adjacent := cell + Vector2i(dx, dy)
				if not cells.has(adjacent):
					exposed.append(adjacent)
		for py in PIXELS_PER_CELL:
			for px in PIXELS_PER_CELL:
				var point := Vector2(cell) + (Vector2(px, py) + Vector2.ONE * 0.5) / PIXELS_PER_CELL
				var distance := 1.0
				for empty in exposed:
					var nearest := point.clamp(Vector2(empty), Vector2(empty + Vector2i.ONE))
					distance = minf(distance, point.distance_to(nearest))
				var feather := 0.20 + noise.get_noise_2d(point.x * 4, point.y * 4) * 0.09
				var alpha := smoothstep(0.018, feather, distance)
				mask_image.set_pixel(
					cell.x * PIXELS_PER_CELL + px,
					cell.y * PIXELS_PER_CELL + py,
					Color(alpha, alpha, alpha)
				)
	if mask_texture == null:
		mask_texture = ImageTexture.create_from_image(mask_image)
	else:
		mask_texture.update(mask_image)
	return true


func canvas_material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://scripts/visuals/volcanic_canvas.gdshader")
	_bind(result)
	return result


func spatial_material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://scripts/visuals/volcanic_spatial.gdshader")
	_bind(result)
	return result


func _bind(material: ShaderMaterial) -> void:
	material.set_shader_parameter("rock_texture", rock_texture)
	material.set_shader_parameter("burn_mask", mask_texture)
	material.set_shader_parameter("seed_phase", float(seed_value % 97) * 0.1)
