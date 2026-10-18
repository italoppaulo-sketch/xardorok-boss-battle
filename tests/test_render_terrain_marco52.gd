extends SceneTree
## Evidência A/B do renderer real; usa o mesmo mundo/células/câmera nos dois lados.
const APPROVED_RENDERER := """extends Node2D
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
"""
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func capture(name_id: String) -> void:
	await RenderingServer.frame_post_draw
	var image2d := root.get_texture().get_image()
	if image2d.save_png("res://docs/capturas/" + name_id + ".png") != OK:
		failures += 1


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Captura exige viewport gráfico real")
		quit(1)
		return
	root.size = Vector2i(1200, 700)
	var battle = load("res://scripts/combat/battle.gd").new()
	battle.random_outcomes = false
	for y in range(3, 7):
		for x in range(6, 10):
			var cell := Vector2i(x, y)
			if cell not in battle.WALLS:
				battle.fire_zones.append({"cell": cell, "expires": 4})
	var arena = load("res://scripts/world/arena.gd").new()
	arena.battle = battle
	root.add_child(arena)
	await create_timer(0.15).timeout
	var modern = arena.fire_fields
	modern.visible = false
	var old_script := GDScript.new()
	old_script.source_code = APPROVED_RENDERER
	if old_script.reload() != OK:
		push_error("Renderer histórico não compila")
		quit(1)
		return
	var old = Node2D.new()
	old.set_script(old_script)
	old.configure(arena)
	old.clock = 0.75
	old.set_process(false)
	arena.add_child(old)
	await create_timer(0.15).timeout
	await capture("marco52_piso_antes")
	old.visible = false
	modern.visible = true
	modern.clock = 0.75
	modern._process(0.0)
	modern.set_process(false)
	await create_timer(0.15).timeout
	await capture("marco52_piso_depois")
	var camera = load("res://scripts/visuals/tactical_zoom.gd").new()
	root.add_child(camera)
	camera.target_zoom = 1.8
	camera.zoom = Vector2.ONE * 1.8
	camera.focus_world(arena.center(Vector2i(8, 4)))
	await create_timer(0.2).timeout
	await capture("marco52_piso_aproximado")
	print("Terrain viewport Marco 5.2: 3 captures; %d failures" % failures)
	arena.queue_free()
	camera.queue_free()
	await process_frame
	quit(1 if failures else 0)
