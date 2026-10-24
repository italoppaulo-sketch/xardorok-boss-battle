extends RefCounted
## Máscara exclusivamente visual; nunca modifica a grade nem calcula dano.
const SAMPLE_STEP := 2
const FIELD_SEED := 5217


static func edge_noise(point: Vector2) -> float:
	return (
		(sin(point.x * 0.173 + sin(point.y * 0.137) * 2.7) + sin(point.y * 0.249 + point.x * 0.071))
		* 0.5
	)


static func cell_set(zones: Array) -> Dictionary:
	var result := {}
	for zone in zones:
		result[Vector2i(zone.cell)] = true
	return result


static func coverage(point: Vector2, cells: Dictionary, tile: float) -> float:
	var cell := Vector2i(floori(point.x / tile), floori(point.y / tile))
	if not cells.has(cell):
		return 0.0
	var local := point - Vector2(cell) * tile
	var edge := tile
	if not cells.has(cell + Vector2i.LEFT):
		edge = minf(edge, local.x)
	if not cells.has(cell + Vector2i.RIGHT):
		edge = minf(edge, tile - local.x)
	if not cells.has(cell + Vector2i.UP):
		edge = minf(edge, local.y)
	if not cells.has(cell + Vector2i.DOWN):
		edge = minf(edge, tile - local.y)
	var irregular := 5.5 + edge_noise(point) * 3.5
	return smoothstep(0.3, 3.3, edge - irregular)


static func make_mask(size: Vector2i, tile: float, zones: Array) -> Image:
	var cells := cell_set(zones)
	var pixels := Vector2i(ceili(size.x * tile / SAMPLE_STEP), ceili(size.y * tile / SAMPLE_STEP))
	var mask := Image.create(pixels.x, pixels.y, false, Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	for y in pixels.y:
		for x in pixels.x:
			var point := Vector2(x * SAMPLE_STEP + 1, y * SAMPLE_STEP + 1)
			var alpha := coverage(point, cells, tile)
			if alpha > 0.0:
				mask.set_pixel(x, y, Color(1, 1, 1, alpha))
	return mask
