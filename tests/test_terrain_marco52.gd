extends SceneTree
const Field = preload("res://scripts/visuals/volcanic_field_2d.gd")
var checks := 0
var failures := 0


func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)


func _initialize() -> void:
	var zones: Array = [{"cell": Vector2i(1, 1)}, {"cell": Vector2i(2, 1)}, {"cell": Vector2i(1, 2)}]
	var cells := Field.cell_set(zones)
	for x in [50.1, 50.5, 51.0, 52.0, 53.0, 54.0, 55.0]:
		expect(Field.coverage(Vector2(x, 75), cells, 50.0) >= 0.0, "Borda irregular tem alfa válido")
	for y in [65.0, 70.0, 75.0, 80.0]:
		expect(
			is_equal_approx(Field.coverage(Vector2(99.9, y), cells, 50.0), 1.0),
			"Fissura compartilhada: esquerda contínua"
		)
		expect(
			is_equal_approx(Field.coverage(Vector2(100.1, y), cells, 50.0), 1.0),
			"Fissura compartilhada: direita contínua"
		)
	var safe_points := [
		Vector2(49.9, 75), Vector2(150.1, 75), Vector2(100, 125),
		Vector2(-1, -1), Vector2(75, 150.1)
	]
	for p in safe_points:
		expect(Field.coverage(p, cells, 50.0) == 0.0, "Célula segura não recebe textura de perigo")
	var a := Field.make_mask(Vector2i(4, 4), 50.0, zones)
	var b := Field.make_mask(Vector2i(4, 4), 50.0, zones)
	expect(a.get_data() == b.get_data(), "Máscara determinística")
	expect(a.get_size() == Vector2i(100, 100), "Máscara pixel art de amostra 2 px")
	var empty := Field.make_mask(Vector2i(4, 4), 50.0, [])
	expect(empty.get_pixel(30, 30).a == 0, "Reinício limpa máscara")
	expect(zones.size() == 3 and not zones[0].has("damage"), "Renderer não altera zonas nem dano")
	var values := {}
	for p in [Vector2(55, 55), Vector2(105, 55), Vector2(55, 105), Vector2(65, 75)]:
		values[Field.edge_noise(p)] = true
	expect(values.size() == 4, "Ruído global não reinicia em cada célula")
	expect(Field.coverage(Vector2(75, 99.9), cells, 50.0) == 1.0, "Continuidade vertical superior")
	expect(Field.coverage(Vector2(75, 100.1), cells, 50.0) == 1.0, "Continuidade vertical inferior")
	print("Terrain Marco 5.2: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
