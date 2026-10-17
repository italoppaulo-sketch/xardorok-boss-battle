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
	for family in ["aura", "shield", "hit_fire", "electric"]:
		textures[family] = load("res://assets/effects/marco5/%s.png" % family)


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
				elif (
					str(effect.get("cause", ""))
					in [
						"aura",
						"shield",
						"meteor",
						"floor",
						"fire_aura",
						"fire_shield",
						"floor_fire"
					]
				):
					_stamp(
						"hit_fire",
						frame,
						point + Vector2(0, 8),
						Vector2(74, 82),
						Color(1, 1, 1, 1 - t)
					)
					for ember in 9:
						var spark := (
							point
							+ Vector2(
								sin(ember * 8.2 + t) * (10 + t * 23), 12 - t * (25 + ember * 5)
							)
						)
						draw_rect(Rect2(spark, Vector2(2, 2)), Color(1, 0.6, 0.12, 1 - t))
			"link":
				var strength := sin(minf(1, t * 1.5) * PI)
				_electric_arc(origin, point, strength, effect.age)
				_stamp(
					"electric",
					mini(3, int(t * 5)),
					point,
					Vector2(78, 78),
					Color(0.75, 1, 1, 1 - t)
				)

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
	if id == "chain":
		# Concentração nas mãos precede os eventos de link reais emitidos pelo combate.
		if t < 0.62:
			var charge := clampf(t / 0.45, 0.2, 1.0)
			_stamp(
				"electric",
				0 if t < 0.3 else 1,
				origin,
				Vector2(38, 38) * charge,
				Color(0.7, 1, 1, 1 - t * 0.5)
			)
			for spark in 6:
				var angle_charge := spark * TAU / 6 + t * 4
				var start := origin + Vector2.from_angle(angle_charge) * (22 * (1 - t))
				draw_line(start, origin, Color(0.3, 0.7, 1, 0.7), 1)
	elif id in ["fire_aura", "fire_shield"]:
		_stamp(
			"aura" if id == "fire_aura" else "shield",
			frame,
			origin + Vector2(0, -10),
			Vector2(110, 100),
			Color(1, 1, 1, 1 - t * 0.6)
		)
	elif id == "red_laser":
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


func _electric_arc(origin: Vector2, point: Vector2, strength: float, age: float) -> void:
	var direction := (point - origin).normalized()
	var normal := direction.orthogonal()
	var segments := clampi(int(origin.distance_to(point) / 14), 5, 30)
	var nodes := PackedVector2Array([origin])
	for step in range(1, segments):
		var ratio := float(step) / segments
		var noise := sin(step * 13.71 + floorf(age * 18) * 4.2) * 10
		nodes.append(origin.lerp(point, ratio) + normal * noise)
	nodes.append(point)
	draw_polyline(nodes, Color(0.08, 0.4, 1, strength * 0.22), 13)
	draw_polyline(nodes, Color(0.2, 0.65, 1, strength), 4)
	draw_polyline(nodes, Color(0.85, 0.98, 1, strength), 1.5)
	for branch in range(2, segments - 1, 3):
		var root := nodes[branch]
		var side := 1.0 if branch % 2 else -1.0
		var tip := root + normal * side * (15 + 8 * sin(age * 22 + branch)) + direction * 13
		var middle := root.lerp(tip, 0.5) - direction * 6
		draw_polyline(
			PackedVector2Array([root, middle, tip]), Color(0.3, 0.8, 1, strength * 0.75), 2
		)
