extends RefCounted


## Mesma percepção para regras, IA e apresentação. Sem conhecimento coletivo através da fumaça.
static func line(a: Vector2i, b: Vector2i, smoke: Array, walls: Array) -> bool:
	for zone in smoke:
		var center := Vector2(zone.cell)
		var from_inside: bool = Vector2(a).distance_to(center) <= zone.radius
		var to_inside: bool = Vector2(b).distance_to(center) <= zone.radius
		var closest := Geometry2D.get_closest_point_to_segment(center, Vector2(a), Vector2(b))
		if not (from_inside and to_inside) and closest.distance_to(center) <= zone.radius:
			return false
	var start := Vector2(a) + Vector2(0.5, 0.5)
	var finish := Vector2(b) + Vector2(0.5, 0.5)
	for wall in walls:
		var rect := Rect2(Vector2(wall), Vector2.ONE)
		var corners := [
			rect.position, rect.position + Vector2(1, 0), rect.end, rect.position + Vector2(0, 1)
		]
		for edge in 4:
			if (
				Geometry2D.segment_intersects_segment(
					start, finish, corners[edge], corners[(edge + 1) % 4]
				)
				!= null
			):
				return false
	return true
