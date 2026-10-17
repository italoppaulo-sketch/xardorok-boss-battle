extends RefCounted
## Uma única fonte para o recorte oval, navegação, seleção e piso desenhado.
const SIZE := Vector2i(15, 9)
const WALLS := [Vector2i(3, 1), Vector2i(11, 1), Vector2i(2, 7), Vector2i(12, 7)]
const ROW_BOUNDS := [
	Vector2i(3, 11),
	Vector2i(1, 13),
	Vector2i(0, 14),
	Vector2i(0, 14),
	Vector2i(0, 14),
	Vector2i(0, 14),
	Vector2i(0, 14),
	Vector2i(1, 13),
	Vector2i(3, 11)
]


static func valid_cell(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= SIZE.y:
		return false
	return cell.x >= ROW_BOUNDS[cell.y].x and cell.x <= ROW_BOUNDS[cell.y].y


static func floor_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if valid_cell(cell):
				cells.append(cell)
	return cells
