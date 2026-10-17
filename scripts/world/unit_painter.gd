extends RefCounted


## Silhuetas de estudo desenhadas no próprio Godot; não são os sprites definitivos.
static func paint(
	canvas: Node2D,
	unit: Dictionary,
	index: int,
	point: Vector2,
	time: float,
	scale2d: float,
	attacking: bool
) -> void:
	var skin := Color("d6ae8c")
	var dark := Color("171a29")
	var ivory := Color("ddd9cb")
	canvas.draw_set_transform(point.floor(), 0, Vector2.ONE * scale2d)
	var lift := -8.0 if unit.statuses.has("flight") else 0.0
	var bob := sin(time * 3 + index) * 1.2
	canvas.draw_set_transform((point + Vector2(0, lift + bob)).floor(), 0, Vector2.ONE * scale2d)
	# Pernas, botas e contorno comum; cada silhueta recebe corpo e acessórios próprios.
	canvas.draw_rect(Rect2(-11, -4, 22, 26), dark)
	canvas.draw_rect(Rect2(-11, 15, 8, 8), Color("10121c"))
	canvas.draw_rect(Rect2(3, 15, 8, 8), Color("10121c"))
	var arm := -6.0 if attacking else 4.0
	match index:
		0:
			canvas.draw_rect(Rect2(-17, -10, 34, 23), Color("423747"))
			canvas.draw_rect(Rect2(-14, -8, 28, 20), skin)
			canvas.draw_rect(Rect2(-19, -6, 7, 17), skin)
			canvas.draw_rect(Rect2(12, -6, 7, 17), skin)
			canvas.draw_line(Vector2(-8, -4), Vector2(0, 7), Color("456c86"), 3)
			canvas.draw_line(Vector2(7, -6), Vector2(4, 3), Color("456c86"), 3)
			canvas.draw_rect(Rect2(-14, 10, 28, 8), Color("a29985"))
			canvas.draw_rect(Rect2(-8, -24, 16, 16), skin)
			canvas.draw_rect(Rect2(-10, -27, 20, 8), Color("a64e2d"))
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-10, -14),
						Vector2(10, -14),
						Vector2(7, -1),
						Vector2(0, 5),
						Vector2(-7, -1)
					]
				),
				Color("bd6132")
			)
			canvas.draw_line(Vector2(20, 15), Vector2(20 + arm, -21), Color("886653"), 4)
			canvas.draw_rect(Rect2(9 + arm, -27, 24, 14), Color("97a6b7"))
			canvas.draw_rect(Rect2(9 + arm, -27, 24, 3), Color("d9e6ed"))
			if unit.statuses.has("ice_hammer"):
				canvas.draw_rect(Rect2(7 + arm, -29, 28, 18), Color(0.45, 0.87, 1, 0.75), false, 3)
		1:
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[Vector2(-11, -9), Vector2(10, -9), Vector2(14, 17), Vector2(-14, 17)]
				),
				Color("242337")
			)
			canvas.draw_line(Vector2(-8, -4), Vector2(8, 10), Color("514666"), 3)
			canvas.draw_rect(Rect2(-12, 7, 24, 4), Color("776095"))
			canvas.draw_rect(Rect2(-7, -24, 14, 15), skin)
			canvas.draw_rect(Rect2(-10, -29, 20, 9), dark)
			canvas.draw_rect(Rect2(-11, -23, 5, 16), dark)
			canvas.draw_rect(Rect2(6, -23, 4, 12), dark)
			canvas.draw_line(Vector2(15, 20), Vector2(20 + arm, -18), Color("9a7bc6"), 3)
			canvas.draw_line(Vector2(14, 13), Vector2(22, 14), Color("ccb18b"), 3)
			canvas.draw_rect(Rect2(-19, arm, 7, 7), skin)
		2:
			canvas.draw_rect(Rect2(-11, -29, 22, 31), Color("151725"))
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[Vector2(-9, -9), Vector2(9, -9), Vector2(17, 22), Vector2(-17, 22)]
				),
				Color("345a9c")
			)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[Vector2(-4, -5), Vector2(4, -5), Vector2(7, 22), Vector2(-6, 22)]
				),
				Color("6a87c0")
			)
			canvas.draw_rect(Rect2(-6, -24, 12, 13), skin)
			canvas.draw_rect(Rect2(-9, -29, 18, 7), Color("151725"))
			canvas.draw_rect(Rect2(-11, 3, 22, 3), Color("b5a16a"))
			canvas.draw_line(Vector2(20, 22), Vector2(20 + arm, -22), Color("9d8b68"), 3)
			canvas.draw_circle(Vector2(20 + arm, -24), 6, Color("a19bed"))
			canvas.draw_circle(Vector2(19 + arm, -26), 2, ivory)
		3:
			canvas.draw_rect(Rect2(-12, -10, 24, 25), Color("2f3d39"))
			canvas.draw_rect(Rect2(-9, -8, 18, 20), Color("45564d"))
			canvas.draw_line(Vector2(-9, -8), Vector2(8, 11), Color("8c7051"), 4)
			canvas.draw_rect(Rect2(-7, -25, 14, 16), skin)
			canvas.draw_rect(Rect2(-10, -28, 20, 8), Color("3b302b"))
			canvas.draw_arc(Vector2(11 + arm, -1), 21, -1.3, 1.3, 12, Color("d3ae73"), 3)
			canvas.draw_line(Vector2(17 + arm, -21), Vector2(17 + arm, 19), Color("d2d5c5"), 1)
			canvas.draw_rect(Rect2(-11, 17, 8, 5), Color("d5b35f"))
			canvas.draw_rect(Rect2(3, 17, 8, 5), Color("d5b35f"))
		4:
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[Vector2(-11, -8), Vector2(11, -8), Vector2(15, 22), Vector2(-15, 22)]
				),
				Color("282338")
			)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-14, -10),
						Vector2(14, -10),
						Vector2(11, 1),
						Vector2(0, -2),
						Vector2(-11, 1)
					]
				),
				ivory
			)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-9, -24),
						Vector2(5, -27),
						Vector2(11, -18),
						Vector2(18, -15),
						Vector2(15, -8),
						Vector2(-7, -8)
					]
				),
				Color("b8584d")
			)
			canvas.draw_colored_polygon(
				PackedVector2Array([Vector2(-9, -22), Vector2(-8, -33), Vector2(-2, -25)]), ivory
			)
			canvas.draw_colored_polygon(
				PackedVector2Array([Vector2(2, -26), Vector2(8, -34), Vector2(8, -22)]), ivory
			)
			canvas.draw_rect(Rect2(7, -20, 3, 3), Color("f1cf71"))
			canvas.draw_circle(Vector2(-17, arm), 4, Color("69cfff"))
		5:
			canvas.draw_rect(Rect2(-18, -9, 36, 29), Color("191920"))
			canvas.draw_rect(Rect2(-23, -12, 12, 15), Color("353039"))
			canvas.draw_rect(Rect2(11, -12, 12, 15), Color("353039"))
			for line in [
				PackedVector2Array([Vector2(-9, -8), Vector2(-3, 0), Vector2(-7, 8)]),
				PackedVector2Array([Vector2(9, -5), Vector2(3, 5), Vector2(6, 16)])
			]:
				canvas.draw_polyline(line, Color("ff8746"), 2)
			canvas.draw_rect(Rect2(-8, -29, 16, 19), skin)
			canvas.draw_rect(Rect2(-11, -30, 5, 14), ivory)
			canvas.draw_rect(Rect2(6, -30, 5, 14), ivory)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-10, -15),
						Vector2(10, -15),
						Vector2(8, 0),
						Vector2(0, 12),
						Vector2(-8, 0)
					]
				),
				ivory
			)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-13, -29),
						Vector2(-14, -41),
						Vector2(-5, -35),
						Vector2(0, -43),
						Vector2(6, -35),
						Vector2(14, -41),
						Vector2(12, -29)
					]
				),
				Color("d6b05f")
			)
			canvas.draw_rect(Rect2(-2, -35, 4, 4), Color("d05b4f"))
			canvas.draw_line(Vector2(24, 18), Vector2(25 + arm, -25), Color("bf9465"), 4)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[Vector2(20 + arm, -23), Vector2(28 + arm, -42), Vector2(34 + arm, -19)]
				),
				Color("ff905a")
			)
		_:
			canvas.draw_rect(Rect2(-11, -8, 22, 28), Color("51454a"))
			canvas.draw_rect(Rect2(-9, -25, 18, 18), Color("69616a"))
			canvas.draw_rect(Rect2(-7, -16, 14, 3), Color("ff905a"))
			canvas.draw_line(Vector2(13, 12), Vector2(18 + arm, -18), Color("c0a390"), 3)
	if unit.statuses.has("ice_skin"):
		for x in [-15, -5, 5, 15]:
			canvas.draw_colored_polygon(
				PackedVector2Array([Vector2(x - 4, 6), Vector2(x, -7), Vector2(x + 4, 6)]),
				Color(0.5, 0.88, 1, 0.8)
			)
	if unit.statuses.has("rooted"):
		canvas.draw_arc(Vector2(0, 17), 17, 0, TAU, 16, Color("85b56d"), 3)
	if unit.statuses.has("frozen"):
		canvas.draw_rect(Rect2(-21, -33, 42, 57), Color(0.5, 0.85, 1, 0.3))
	if unit.statuses.has("silenced"):
		canvas.draw_arc(Vector2(0, -36), 8, 0, TAU, 16, Color("a5a1e8"), 2)
		canvas.draw_line(Vector2(-6, -42), Vector2(6, -30), Color("a5a1e8"), 2)
	canvas.draw_set_transform(Vector2.ZERO)
