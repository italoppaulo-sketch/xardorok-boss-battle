extends Node2D
## Campo 2D contínuo sobre a lista visual de incêndios. Não altera regras de dano.
const Field = preload("res://scripts/visuals/volcanic_field_2d.gd")
const FieldShader = preload("res://scripts/visuals/volcanic_field_2d.gdshader")
const Rock = preload("res://assets/effects/marco52/volcanic_reference.png")
var arena: Node2D
var clock := 0.0
var mask_texture: ImageTexture
var cached_cells := {}
var field_material: ShaderMaterial
var bounds := Rect2()


func configure(arena_node: Node2D) -> void:
	arena = arena_node
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -1
	field_material = ShaderMaterial.new()
	field_material.shader = FieldShader
	field_material.set_shader_parameter("rock_texture", Rock)
	material = field_material


func _process(delta: float) -> void:
	clock += delta
	if arena == null:
		return
	var cells := Field.cell_set(arena.visual_fire)
	if cells != cached_cells or mask_texture == null:
		cached_cells = cells
		var tile: float = arena.TILE
		var size: Vector2i = arena.Battle.SIZE
		bounds = Rect2(arena.ORIGIN, Vector2(size) * tile)
		var mask := Field.make_mask(size, tile, arena.visual_fire)
		if mask_texture == null:
			mask_texture = ImageTexture.create_from_image(mask)
		else:
			mask_texture.update(mask)
		field_material.set_shader_parameter("field_size", bounds.size)
		queue_redraw()
	field_material.set_shader_parameter("phase", clock)


func _draw() -> void:
	if mask_texture != null and not cached_cells.is_empty():
		draw_texture_rect(mask_texture, bounds, false)
