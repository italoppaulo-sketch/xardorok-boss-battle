extends SceneTree
const Surface = preload("res://scripts/visuals/volcanic_surface.gd")
const Battle = preload("res://scripts/combat/battle.gd")
var checks := 0
var failures := 0


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var surface := Surface.new(Vector2i(15, 9), 5107)
	expect(surface.rock_texture.get_width() == 506, "Uses actual user supplied photograph")
	expect(surface.mask_image.get_pixel(16, 16).r == 0.0, "No fire means no volcanic floor")
	var zones: Array = [
		{"cell": Vector2i(4, 3)}, {"cell": Vector2i(5, 3)}, {"cell": Vector2i(5, 4)}
	]
	expect(surface.update_zones(zones), "New logical hazard activates visual mask")
	var mask := surface.mask_image
	expect(
		mask.get_pixel(4 * 32 + 31, 3 * 32 + 16).r > 0.95,
		"First cell has continuous interior at shared border"
	)
	expect(
		mask.get_pixel(5 * 32, 3 * 32 + 16).r > 0.95,
		"Second cell has continuous interior at shared border"
	)
	expect(mask.get_pixel(6 * 32 + 4, 3 * 32 + 16).r == 0.0, "Safe adjacent cell has zero lava")
	expect(
		mask.get_pixel(4 * 32 + 16, 3 * 32 + 16).r > 0.99,
		"Hazard centers remain clearly identified"
	)
	expect(mask.get_pixel(4 * 32, 3 * 32 + 16).r < 0.2, "Exterior edge feathers inward")
	var duplicate := Surface.new(Vector2i(15, 9), 5107)
	duplicate.update_zones(zones)
	expect(
		mask.get_data() == duplicate.mask_image.get_data(),
		"Same seed and zones produce byte identical mask"
	)
	var varied := Surface.new(Vector2i(15, 9), 5108)
	varied.update_zones(zones)
	expect(
		mask.get_data() != varied.mask_image.get_data(),
		"Different seed changes organic edge shapes"
	)
	var identity: Texture2D = surface.mask_texture
	expect(not surface.update_zones(zones), "Unchanged zones do not rebuild or allocate textures")
	zones.reverse()
	expect(not surface.update_zones(zones), "Zone ordering does not cause visual variation")
	var canvas := surface.canvas_material()
	var spatial := surface.spatial_material()
	expect(
		canvas.get_shader_parameter("burn_mask") == identity, "2D material binds authoritative mask"
	)
	expect(
		spatial.get_shader_parameter("burn_mask") == identity,
		"3D material binds identical authoritative mask"
	)
	surface.update_zones([])
	expect(
		surface.mask_texture == identity, "Texture identity survives extinguish for both materials"
	)
	expect(
		surface.mask_image.get_pixel(4 * 32 + 16, 3 * 32 + 16).r == 0,
		"Extinguished fire disappears"
	)
	surface.update_zones(
		[{"cell": Vector2i(-1, 3)}, {"cell": Vector2i(15, 2)}, {"cell": Vector2i(3, 1)}],
		Battle.WALLS
	)
	expect(surface.cells.is_empty(), "Out of arena and wall cells never display hazards")
	var battle := Battle.new()
	var hp: int = battle.units[0].hp
	var snapshot: Array = battle.units.duplicate(true)
	surface.update_zones([{"cell": battle.units[0].cell}])
	for frame in 12:
		surface.update_zones([{"cell": battle.units[0].cell}])
	expect(
		battle.units[0].hp == hp and battle.units == snapshot,
		"Animation and masking never mutate combat or HP"
	)
	var arena: Node2D = load("res://scripts/world/arena.gd").new()
	arena.battle = battle
	root.add_child(arena)
	await process_frame
	arena.visual_fire.assign([{"cell": Vector2i(4, 3)}, {"cell": Vector2i(5, 3)}])
	arena.fire_fields._process(0.1)
	expect(
		arena.fire_fields.surface.cells.size() == 2,
		"Existing 2D arena integrates actual snapshot zones"
	)
	expect(
		arena.fire_fields.layer.material is ShaderMaterial,
		"Original presentation uses continuous canvas shader"
	)
	arena.queue_free()
	await process_frame
	print("Terrain Marco 5.1: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
