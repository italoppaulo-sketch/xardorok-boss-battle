extends Node2D
## Animações de eventos do modelo, sem alterar resultados de combate.
const FONT_SIZE := 16
var active: Array[Dictionary] = []


func add_event(event: Dictionary, from: Vector2, to: Vector2) -> void:
	var effect := event.duplicate(true)
	effect.from = from
	effect.to = to
	effect.age = -float(event.get("delay", 0.0))
	effect.life = 1.2 if event.kind in ["damage", "heal", "recoil", "miss"] else 0.7
	active.append(effect)


func _process(delta: float) -> void:
	for effect in active.duplicate():
		effect.age += delta
		if effect.age > effect.life:
			active.erase(effect)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for effect in active:
		if effect.age < 0:
			continue
		var t: float = effect.age / effect.life
		var color := Color(effect.get("color", "ffffff"))
		color.a = 1.0 - t
		var origin: Vector2 = effect.from
		var point: Vector2 = effect.to
		match effect.kind:
			"damage", "heal", "recoil", "miss":
				var text := "ESQUIVA" if effect.kind == "miss" else str(effect.get("amount", 0))
				if effect.kind == "heal":
					text = "+" + text
				if effect.get("critical", false):
					text = "CRÍTICO " + text
				var float_position := point + Vector2(-22, -42 - t * 38)
				draw_string(
					font,
					float_position + Vector2(1, 2),
					text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					FONT_SIZE,
					Color(0, 0, 0, 1 - t)
				)
				draw_string(
					font, float_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color
				)
			"link":
				var middle := origin.lerp(point, 0.5) + Vector2(0, sin(t * 60) * 13)
				draw_polyline(PackedVector2Array([origin, middle, point]), color, 4)
				draw_line(origin, point, Color(0.85, 0.95, 1, 1 - t), 1)
			"meteor":
				draw_line(point + Vector2(-40, -100) * (1 - t), point, color, 9)
				draw_circle(point, 12 + t * 36, Color(1, 0.35, 0.08, (1 - t) * 0.5))
				_sparks(point, color, t)
			"cast":
				var id: String = effect.ability
				if id == "fushigiri":
					draw_line(origin, point, Color(0.25, 0.08, 0.4, (1 - t) * 0.8), 19)
					draw_line(
						point + Vector2(-30, -44) * (1 - t),
						point + Vector2(28, 30) * (1 - t),
						color,
						6
					)
					draw_line(
						point + Vector2(26, -38) * (1 - t),
						point + Vector2(-25, 25) * (1 - t),
						Color(0.95, 0.8, 1, 1 - t),
						2
					)
				elif id in ["root_arrow", "ice_arrow", "energy_arrow", "purple_fire"]:
					var head := origin.lerp(point, clampf(t * 3, 0, 1))
					draw_line(
						head, head.move_toward(origin, 24), color, 5 if id != "purple_fire" else 9
					)
					draw_circle(head, 4, color)
					if t > 0.3:
						_sparks(point, color, (t - 0.3) / 0.7)
					if id == "ice_arrow" and t > 0.3:
						for angle in 8:
							var base := point + Vector2.from_angle(angle * TAU / 8) * 27
							draw_colored_polygon(
								PackedVector2Array(
									[
										base + Vector2(-5, 5),
										base + Vector2(0, -22 * (1 - t)),
										base + Vector2(5, 5)
									]
								),
								color
							)
				elif id in ["basic", "double", "unarmed"]:
					draw_arc(point, 14 + t * 15, -2.5 + t, 0.6 + t, 12, color, 4)
					if id in ["double", "unarmed"]:
						draw_arc(point, 10 + t * 18, 0.5 + t, 3.2 + t, 12, color, 3)
				else:
					draw_arc(point, 12 + t * 25, 0, TAU, 24, color, 2)
					_sparks(point, color, t)
			"status", "dispel", "spawn":
				draw_arc(point, 10 + t * 24, 0, TAU, 24, color, 2)


func _sparks(point: Vector2, color: Color, t: float) -> void:
	for i in 9:
		var direction := Vector2.from_angle(i * TAU / 9)
		var position2d := point + direction * (6 + t * 40) + Vector2(0, t * t * 18)
		draw_rect(Rect2(position2d, Vector2.ONE * 3), color)
