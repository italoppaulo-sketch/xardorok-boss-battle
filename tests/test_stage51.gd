extends SceneTree
const Stage := preload("res://scripts/camera/arena_stage3d.gd")
const Geometry := preload("res://scripts/combat/arena_geometry.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func _run() -> void:
	var stage := Stage.new()
	root.add_child(stage)
	stage.setup()
	stage.setup()
	check(
		stage.floor_root.get_child_count() == 238, "119 planes and119 foundations; setup idempotent"
	)
	check(stage.flame_sprites.size() == 4, "four supported braziers")
	check(Stage.logical_to_world(Vector2i(7, 4)) == Vector3.ZERO, "logical centre")
	check(Stage.logical_to_world(Vector2i.ZERO) == Vector3(-7, 0, -4), "logical origin")
	var ground := stage.get_node("SoloSelecao") as StaticBody3D
	check(ground.collision_layer == 4, "selection ground layer4")
	for index in Geometry.WALLS.size():
		var obstacle := stage.get_node("Obstaculo%d" % index) as StaticBody3D
		check(obstacle.collision_layer == 1, "obstacle layer1")
		check(
			obstacle.position.distance_to(Stage.logical_to_world(Geometry.WALLS[index])) < 0.5,
			"support matches logical WALLS"
		)
	await physics_frame
	await physics_frame
	var space := stage.get_world_3d().direct_space_state
	for cell in Geometry.floor_cells():
		var at := Stage.logical_to_world(cell)
		var query := PhysicsRayQueryParameters3D.create(
			at + Vector3.UP * 10, at + Vector3.DOWN * 2, 4
		)
		var hit := space.intersect_ray(query)
		check(not hit.is_empty(), "floor pick %s" % cell)
		var blocked := PhysicsRayQueryParameters3D.create(
			at + Vector3.UP * 10, at + Vector3.DOWN * 2, 1
		)
		check(
			(not space.intersect_ray(blocked).is_empty()) == (cell in Geometry.WALLS),
			"only logical obstacles collide %s" % cell
		)
	stage.free()
	print("STAGE51: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
