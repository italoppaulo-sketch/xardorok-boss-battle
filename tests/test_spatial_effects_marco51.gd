extends SceneTree
## Confronta o shader com o framebuffer: célula perigosa assimétrica vs espelho seguro.
const Support = preload("res://scripts/support/spirit_support.gd")
var scene: Node
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func framebuffer() -> Image:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func difference(a: Image, b: Image, point: Vector2) -> float:
	var total := 0.0
	for y in range(-3, 4):
		for x in range(-3, 4):
			var pixel := Vector2i(point) + Vector2i(x, y)
			var first := a.get_pixelv(pixel)
			var second := b.get_pixelv(pixel)
			total += absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b)
	return total / (49.0 * 3.0)


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Teste exige framebuffer gráfico real")
		quit(1)
		return
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.arena.orbit.set_orbit(0, 0.9, true)
	var danger := Vector2i(6, 2)
	var safe := Vector2i(6, 6)
	var danger_screen: Vector2 = scene.arena.project_cell(danger)
	var safe_screen: Vector2 = scene.arena.project_cell(safe)
	var before := await framebuffer()
	scene.battle.FireRules.ignite(scene.battle, danger, 0)
	scene.arena.capture_state()
	var burning := await framebuffer()
	var danger_diff := difference(before, burning, danger_screen)
	var safe_diff := difference(before, burning, safe_screen)
	expect(
		scene.battle.is_burning_cell(danger) and not scene.battle.is_burning_cell(safe),
		"Modelo: perigo (6,2), espelho (6,6) seguro"
	)
	expect(danger_diff > 0.025, "GPU altera textura na célula lógica perigosa")
	expect(safe_diff < danger_diff * 0.25 + 0.003, "GPU não espelha fogo em célula segura")
	expect(
		burning.save_png("res://docs/capturas/marco51_lava_correspondencia.png") == OK,
		"Captura do piso assimétrico real"
	)
	scene.battle.fire_zones.clear()
	scene.arena.capture_state()
	var cleared := await framebuffer()
	var clear_diff := difference(before, cleared, danger_screen)
	expect(clear_diff < danger_diff * 0.25 + 0.003, "Extinção remove textura da célula correta")
	scene.battle.events.clear()
	Support.grant(scene.battle)
	scene.arena.present(scene.battle.events)
	await create_timer(0.65).timeout
	expect(
		is_instance_valid(scene.arena.spirit_billboard) and scene.arena.spirit_billboard.visible,
		"Dalamud manifesta billboard espiritual"
	)
	expect(
		scene.battle.units.size() == 6 and scene.battle.has_status(1, "attack"),
		"Espírito não cria unidade física e concede buff real"
	)
	var spirit_image := await framebuffer()
	expect(
		spirit_image.save_png("res://docs/capturas/marco51_dalamud_espirito.png") == OK,
		"Captura da manifestação espiritual real"
	)
	print(
		(
			(
				"Marco5.1 GPU espacial: %d verificações; %d falhas; "
				+ "delta perigoso %.5f; seguro %.5f; extinto %.5f"
			)
			% [checks, failures, danger_diff, safe_diff, clear_diff]
		)
	)
	quit(1 if failures else 0)
