extends Node2D
## Organic surface follows combat snapshots. This renderer never deals damage.
const Surface = preload("res://scripts/visuals/volcanic_surface.gd")
var arena: Node2D
var clock := 0.0
var surface: RefCounted
var layer := Sprite2D.new()


func configure(arena_node: Node2D) -> void:
	arena = arena_node
	z_index = -1
	surface = Surface.new(arena.Battle.SIZE)
	layer.texture = surface.rock_texture
	layer.centered = false
	layer.position = arena.ORIGIN
	layer.scale = Vector2(arena.Battle.SIZE) * arena.TILE / layer.texture.get_size()
	layer.material = surface.canvas_material()
	add_child(layer)


func _process(delta: float) -> void:
	clock += delta
	if arena != null:
		surface.update_zones(arena.visual_fire, arena.Battle.WALLS)
	queue_redraw()


func _draw() -> void:
	if arena == null:
		return
	# Sparse embers are independent and desynchronised; no repeated flame stamp.
	for zone in arena.visual_fire:
		var cell: Vector2i = zone.cell
		var salt := float(posmod(cell.x * 37 + cell.y * 113, 101)) / 101.0
		var rise := fmod(clock * 0.29 + salt, 1.0)
		if rise > 0.55:
			continue
		var origin: Vector2 = arena.center(cell) + Vector2(sin(salt * 23) * 18, cos(salt * 17) * 15)
		draw_circle(
			origin + Vector2(sin(clock + salt * 9) * 3, -rise * 48),
			1.1,
			Color(1, 0.44 + salt * 0.3, 0.08, 0.55 - rise)
		)
