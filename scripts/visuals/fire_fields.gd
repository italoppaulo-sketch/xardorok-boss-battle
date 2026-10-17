extends Node2D
## Chamas temporárias nas células que o combate já marcou. Sem cálculo de dano.
var arena: Node2D
var clock := 0.0
var texture: Texture2D = preload("res://assets/effects/marco5/floor_fire.png")
var scorch: Texture2D = preload("res://assets/effects/marco5/floors.png")


func configure(arena_node: Node2D) -> void:
	arena = arena_node
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -1


func _process(delta: float) -> void:
	clock += delta
	queue_redraw()


func _draw() -> void:
	if arena == null:
		return
	for zone in arena.visual_fire:
		var cell: Vector2i = zone.cell
		var point: Vector2 = arena.center(cell)
		var frame := (int(clock * 8) + cell.x + cell.y) % 4
		draw_texture_rect_region(
			scorch,
			Rect2(point - Vector2(25, 25), Vector2(50, 50)),
			Rect2(288, 0, 96, 96),
			Color(1, 0.8, 0.65, 0.8)
		)
		draw_texture_rect_region(
			texture,
			Rect2(point - Vector2(28, 43), Vector2(56, 64)),
			Rect2(frame * 96, 0, 96, 96),
			Color(1, 1, 1, 0.93)
		)
		for i in 3:
			var rise := fmod(clock * 0.8 + i * 0.3, 1.0)
			draw_rect(
				Rect2(point + Vector2(sin(i * 4.1 + clock) * 17, -rise * 45), Vector2(2, 2)),
				Color(1, 0.6, 0.12, 1 - rise)
			)
