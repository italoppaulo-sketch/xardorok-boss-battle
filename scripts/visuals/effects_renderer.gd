extends Node2D
## Texturas de magia e feedback. Esta camada nunca aplica dano.
const FAMILIES := [
	"ice", "fire", "lightning", "arrows", "illusion", "healing", "smoke", "meteor", "laser"
]
const FONT_SIZE := 16
var active: Array[Dictionary] = []
var textures := {}


func _ready() -> void:
	z_index = 30
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for family in FAMILIES:
		textures[family] = load("res://assets/effects/%s/atlas.png" % family)


func add_event(event: Dictionary, from: Vector2, to: Vector2) -> void:
	var effect := event.duplicate(true)
	effect.from = from
	effect.to = to
	effect.age = -float(event.get("delay", 0.0))
	effect.life = 1.0 if event.kind in ["damage", "heal", "recoil", "miss"] else 0.8
	if event.kind in ["phase", "reaction"]:
		effect.life = 1.5
	active.append(effect)


func _process(delta: float) -> void:
	for effect in active.duplicate():
		effect.age += delta
		if effect.age > effect.life:
			active.erase(effect)
	queue_redraw()


func _stamp(
	family: String,
	frame: int,
	point: Vector2,
	dimensions: Vector2,
	color: Color = Color.WHITE,
	angle: float = 0.0
) -> void:
	if not textures.has(family):
		return
	draw_set_transform(point, angle)
	draw_texture_rect_region(
		textures[family],
		Rect2(-dimensions * 0.5, dimensions),
		Rect2(clampi(frame, 0, 3) * 96, 0, 96, 96),
		color
	)
	draw_set_transform(Vector2.ZERO)


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
		var frame := mini(3, int(t * 4))
		match effect.kind:
			"phase", "reaction":
				var phase_change: bool = effect.kind == "phase"
				var title := (
					"FASE 2 — A IRA DO REI"
					if phase_change
					else (
						"REAÇÃO — %s"
						% (
							"COMANDO DAS CINZAS"
							if effect.get("ability", "") == "command"
							else "BRASA ANUNCIADA"
						)
					)
				)
				draw_rect(Rect2(330, 104, 540, 48), Color(0.08, 0.05, 0.04, minf(0.9, (1 - t) * 2)))
				draw_string(
					ThemeDB.fallback_font,
					Vector2(350, 126),
					title,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					18,
					Color(1, 0.76, 0.42, 1 - t)
				)
				if not phase_change:
					draw_string(
						ThemeDB.fallback_font,
						Vector2(350, 144),
						"Aviso tático; a iniciativa normal continua.",
						HORIZONTAL_ALIGNMENT_LEFT,
						-1,
						12,
						Color(0.9, 0.85, 0.75, 1 - t)
					)
				if not effect.get("hide_source", false):
					_stamp(
						"meteor",
						frame,
						origin,
						Vector2(124, 124) if phase_change else Vector2(74, 74),
						Color(1, 0.7, 0.4, (1 - t) * 0.7)
					)
			"damage", "heal", "recoil", "miss":
				var text := "ESQUIVA" if effect.kind == "miss" else str(effect.get("amount", 0))
				if effect.kind == "heal":
					text = "+" + text
				if effect.get("critical", false):
					text = "CRÍTICO " + text
				var at := point + Vector2(-22, -30 - t * 35)
				draw_string(
					font,
					at + Vector2(1, 2),
					text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					FONT_SIZE,
					Color(0, 0, 0, 1 - t)
				)
				draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
				if effect.kind == "heal":
					_stamp("healing", frame, point, Vector2(72, 72), Color(1, 1, 1, 1 - t))
			"link":
				var middle := origin.lerp(point, 0.5) + Vector2(0, sin(t * 60) * 10)
				draw_polyline(
					PackedVector2Array([origin, middle, point]), Color(0.2, 0.65, 1, 1 - t), 3
				)
				draw_line(origin, point, Color(0.8, 0.95, 1, 1 - t), 1)
				_stamp("lightning", frame, point, Vector2(62, 62), Color(1, 1, 1, 1 - t))
			"meteor":
				if effect.age < 0.3:
					var falling: Vector2 = point + Vector2(-45, -150) * (1.0 - effect.age / 0.3)
					_stamp("meteor", 0 if frame == 0 else 1, falling, Vector2(72, 72))
				else:
					for at in effect.get("area_centers", [point]):
						_stamp(
							"meteor",
							2 if t < 0.7 else 3,
							at,
							Vector2(48, 48),
							Color(1, 1, 1, 1 - t)
						)
			"cast":
				_cast(effect, t, frame, origin, point)
			"dispel", "status", "spawn":
				var family := (
					"smoke"
					if effect.kind == "spawn"
					else ("healing" if effect.kind == "dispel" else "illusion")
				)
				_stamp(family, frame, point, Vector2(56, 56), Color(1, 1, 1, 0.7 * (1 - t)))


func _cast(effect: Dictionary, t: float, frame: int, origin: Vector2, point: Vector2) -> void:
	var id: String = effect.ability
	var angle := origin.angle_to_point(point)
	if id == "red_laser":
		if t < 0.3:
			_stamp("laser", 0, origin, Vector2(46, 46))
		elif t < 0.78:
			var width := origin.distance_to(point) + 20
			_stamp(
				"laser",
				1 if t < 0.48 else 2,
				origin.lerp(point, 0.5),
				Vector2(width, 35),
				Color.WHITE,
				angle
			)
			_stamp("laser", 3, point, Vector2(62, 62))
		else:
			_stamp("laser", 3, point, Vector2(60, 60), Color(1, 1, 1, (1 - t) * 3))
	elif id in ["root_arrow", "ice_arrow", "energy_arrow", "purple_fire"]:
		var head := origin.lerp(point, clampf(t * 1.9, 0, 1))
		var family := "fire" if id == "purple_fire" else "arrows"
		var tint := (
			Color(0.6, 1, 0.6)
			if id == "root_arrow"
			else (Color(0.6, 0.9, 1) if id == "ice_arrow" else Color.WHITE)
		)
		if t < 0.62:
			_stamp(family, mini(1, frame), head, Vector2(66, 40), tint, angle)
		else:
			_stamp(
				"ice" if id == "ice_arrow" else family,
				2 if t < 0.8 else 3,
				point,
				Vector2(80, 80),
				Color(1, 1, 1, (1 - t) * 2)
			)
	elif id == "fushigiri":
		_stamp("illusion", frame, point, Vector2(110, 92), Color(1, 0.45, 1, 1 - t))
		if t > 0.15 and t < 0.75:
			draw_line(
				point + Vector2(-42, -45), point + Vector2(38, 34), Color(0.35, 0.05, 0.6, 0.7), 15
			)
			draw_line(
				point + Vector2(-42, -45), point + Vector2(38, 34), Color(0.9, 0.65, 1, 1 - t), 3
			)
	elif id in ["basic", "double", "unarmed"]:
		var color := Color(effect.get("color", "e5d1a1"))
		color.a = 1 - t
		if t < 0.6:
			draw_arc(point, 18 + t * 15, -2.5 + t, 0.6 + t, 12, color, 3)
		if id in ["double", "unarmed"] and t > 0.35:
			draw_arc(point, 12 + t * 18, 0.5 + t, 3.2 + t, 12, color, 3)
	else:
		var families := {
			"skin": "ice",
			"hammer": "ice",
			"giant": "ice",
			"dodge": "illusion",
			"flight": "arrows",
			"illusion": "illusion",
			"silence": "illusion",
			"heal": "healing",
			"antispell": "healing",
			"smoke": "smoke",
			"meteors": "meteor",
			"summon": "smoke",
			"chain": "lightning"
		}
		var family: String = families.get(id, "illusion")
		_stamp(family, frame, point, Vector2(78, 78), Color(1, 1, 1, 1 - t))
