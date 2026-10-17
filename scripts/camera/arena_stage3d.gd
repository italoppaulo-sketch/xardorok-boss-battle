extends Node3D
## Render-only 2.5D arena. Cell geometry and combat remain authoritative.
const Geometry := preload("res://scripts/combat/arena_geometry.gd")
const BASE := "res://assets/environments/xardorok_arena/marco4/"
var floor_root: Node3D
var architecture_root: Node3D
var flame_sprites: Array[Sprite3D] = []
var flame_lights: Array[OmniLight3D] = []
var clock := 0.0
var initialized := false


static func logical_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x - 7, 0, cell.y - 4)


func setup() -> void:
	if initialized:
		return
	initialized = true
	name = "CitadelaDasCinzas"
	floor_root = Node3D.new()
	floor_root.name = "Piso119Celulas"
	add_child(floor_root)
	architecture_root = Node3D.new()
	architecture_root.name = "RuinasVolumetricasExternas"
	add_child(architecture_root)
	_build_floor()
	_build_architecture()
	_build_lighting()


func _stone(texture_name: String, tint := Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(BASE + texture_name + ".png")
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.95
	return material


func _box(
	parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


func _collision(
	parent: Node3D, label: String, at: Vector3, size: Vector3, layer: int
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = at
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func _build_floor() -> void:
	var variants: Array[StandardMaterial3D] = [
		_stone("floor_0"), _stone("floor_1"), _stone("floor_crack")
	]
	var side := _stone("fascia", Color(0.52, 0.47, 0.43))
	var random := RandomNumberGenerator.new()
	random.seed = 510027
	for cell in Geometry.floor_cells():
		var surface := MeshInstance3D.new()
		surface.name = "Celula_%d_%d" % [cell.x, cell.y]
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE
		surface.mesh = plane
		surface.material_override = variants[random.randi_range(0, 2)]
		surface.position = logical_to_world(cell)
		surface.set_meta("cell", cell)
		floor_root.add_child(surface)
		_box(
			floor_root,
			"Fundacao",
			surface.position + Vector3(0, -0.22, 0),
			Vector3(1, 0.42, 1),
			side
		)
	# Picking plane covers the bounding rectangle. Adapter must filter Geometry.valid_cell.
	_collision(self, "SoloSelecao", Vector3(0, -0.045, 0), Vector3(15, 0.08, 9), 4)
	for index in Geometry.WALLS.size():
		var cell: Vector2i = Geometry.WALLS[index]
		var at := logical_to_world(cell)
		var pedestal := _box(
			self,
			"SuporteBraseiro%d" % index,
			at + Vector3(0, 0.37, 0),
			Vector3(0.82, 0.74, 0.82),
			side
		)
		pedestal.set_meta("blocked_cell", cell)
		_collision(
			self, "Obstaculo%d" % index, at + Vector3(0, 0.44, 0), Vector3(0.9, 0.88, 0.9), 1
		)
		_brazier(at, index)


func _brazier(at: Vector3, index: int) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "Braseiro%d" % index
	sprite.texture = load(BASE + "brazier.png")
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.025
	sprite.position = at + Vector3(0, 1.1, 0)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.no_depth_test = false
	add_child(sprite)
	var flame := Sprite3D.new()
	flame.name = "Chama%d" % index
	var flame_region := AtlasTexture.new()
	flame_region.atlas = load("res://assets/effects/marco5/floor_fire.png")
	flame_region.region = Rect2(index * 96, 26, 96, 70)
	flame.texture = flame_region
	flame.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flame.pixel_size = 0.013
	flame.position = at + Vector3(0, 1.65, 0)
	flame.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	flame.modulate = Color(1, 0.75, 0.48)
	add_child(flame)
	flame_sprites.append(flame)
	var light := OmniLight3D.new()
	light.name = "LuzFogo%d" % index
	light.position = at + Vector3(0, 1.6, 0)
	light.light_color = Color("ff8c42")
	light.light_energy = 0.7
	light.omni_range = 3.2
	light.shadow_enabled = false
	add_child(light)
	flame_lights.append(light)


func _build_architecture() -> void:
	var stone := _stone("floor_crack", Color(0.53, 0.49, 0.47))
	var dark := _stone("floor_1", Color(0.4, 0.39, 0.42))
	# Full pillars and lintels give the original arch cards thickness from side angles.
	# Every footprint is outside the logical arena, including the widest row.
	for side in [-1, 1]:
		for row in [-1, 1]:
			var origin := Vector3(side * 9.1, 0, row * 4.8)
			var group := Node3D.new()
			group.name = "Arco_%d_%d" % [side, row]
			group.position = origin
			architecture_root.add_child(group)
			for leg in [-1, 1]:
				var height := 5.5 if leg == row else 4.8
				_box(
					group,
					"Coluna",
					Vector3(0, height * 0.5, leg * 1.1),
					Vector3(1.1, height, 0.9),
					stone
				)
				_box(group, "Base", Vector3(0, 0.18, leg * 1.1), Vector3(1.6, 0.36, 1.3), dark)
				_box(
					group, "Capitel", Vector3(0, height, leg * 1.1), Vector3(1.35, 0.3, 1.12), stone
				)
			_box(group, "ArcoPartido", Vector3(0, 5.1, 0.15), Vector3(1.1, 0.55, 2.1), stone)
			var card := Sprite3D.new()
			card.name = "RelevoOriginal"
			card.texture = load(BASE + "arch_%d.png" % (0 if side < 0 else 3))
			card.pixel_size = 0.033
			card.position = Vector3(side * 0.57, 2.8, 0)
			card.rotation.y = PI * 0.5
			card.double_sided = true
			card.shaded = true
			card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			group.add_child(card)
	# Broken towers behind the arena form silhouettes, without covering playable ground.
	for index in 7:
		var x := float(index - 3) * 3.3
		var height := 3.3 + float(posmod(index * 7, 5)) * 0.65
		_box(
			architecture_root,
			"TorreDistante%d" % index,
			Vector3(x, height * 0.5, -8.5),
			Vector3(1.5, height, 1.7),
			dark
		)
		_box(
			architecture_root,
			"Coroamento%d" % index,
			Vector3(x, height, -8.5),
			Vector3(1.8, 0.3, 2.0),
			stone
		)


func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "AtmosferaCinzas"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("151722")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9698ad")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.name = "LuzTempestade"
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_color = Color("c4ccdf")
	light.light_energy = 0.85
	light.shadow_enabled = false
	add_child(light)


func _process(delta: float) -> void:
	clock += delta
	for index in flame_sprites.size():
		(flame_sprites[index].texture as AtlasTexture).region.position.x = (
			posmod(int(clock * 8.0) + index, 4) * 96
		)
		flame_lights[index].light_energy = 0.63 + sin(clock * 5.0 + index * 1.7) * 0.1
