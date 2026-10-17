# gdlint: disable=max-public-methods,max-returns
extends "res://scripts/world/arena.gd"
## Adaptador de apresentação. O mesmo Arena mantém cronologia e snapshots de combate.
const Stage3D = preload("res://scripts/camera/arena_stage3d.gd")
const Orbit = preload("res://scripts/camera/tactical_orbit.gd")
const Surface = preload("res://scripts/visuals/volcanic_surface.gd")
var world_view := SubViewport.new()
var view_container := SubViewportContainer.new()
var stage := Stage3D.new()
var orbit := Orbit.new()
var actor_views := {}
var billboards := {}
var shadows := {}
var lava_surface: RefCounted
var lava_plane := MeshInstance3D.new()
var spatial_overlay: Node2D
var smoke_cards := {}
var world_root := Node3D.new()
var hover_index := -1
var camera_hint := Label.new()
var spirit_view: SubViewport
var spirit_billboard: Sprite3D
var spirit_cell := Vector2i(5, 4)


func _ready() -> void:
	super._ready()
	environment.hide()
	sorting.hide()
	fog.hide()
	fire_fields.hide()
	overlay.hide()
	view_container.size = Vector2(1200, 700)
	view_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_container.stretch = true
	add_child(view_container)
	move_child(view_container, 0)
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/environments/xardorok_arena/marco4/storm_distance.png")
	backdrop.size = Vector2(1200, 700)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.65, 0.61, 0.59)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
	world_view.size = Vector2i(1200, 700)
	world_view.own_world_3d = true
	world_view.transparent_bg = true
	world_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view_container.add_child(world_view)
	world_view.add_child(world_root)
	world_root.add_child(stage)
	stage.setup()
	orbit.process_priority = -10
	world_root.add_child(orbit)
	orbit.focus_requested.connect(func(): focus_selected())
	lava_surface = Surface.new(Battle.SIZE, 5107)
	var plane := PlaneMesh.new()
	plane.size = Vector2(15, 9)
	lava_plane.mesh = plane
	lava_plane.position.y = 0.018
	lava_plane.material_override = lava_surface.spatial_material()
	world_root.add_child(lava_plane)
	spatial_overlay = Node2D.new()
	spatial_overlay.set_script(load("res://scripts/camera/spatial_overlay.gd"))
	spatial_overlay.arena = self
	add_child(spatial_overlay)
	camera_hint.position = Vector2(10, 126)
	camera_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	camera_hint.add_theme_constant_override("shadow_offset_y", 1)
	camera_hint.add_theme_font_size_override("font_size", 11)
	camera_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(camera_hint)
	_sync_spatial()


func _draw() -> void:
	pass


func world_cell(cell: Vector2i) -> Vector3:
	return Vector3(cell.x - 7, 0, cell.y - 4)


func displayed_world(index: int) -> Vector3:
	var cell: Vector2 = displayed_cell(index)
	return Vector3(cell.x - 7, 0, cell.y - 4)


func project_world(point: Vector3) -> Vector2:
	return orbit.camera.unproject_position(point)


func crown_screen_at(fall: float, bounce: float) -> Vector2:
	var point := (
		displayed_world(5)
		+ orbit.camera.global_basis.y * ((1 - fall) * (1 - fall) * 2 + bounce / 50.0)
		+ Vector3(fall * 0.5, 0.15, fall * 0.2)
	)
	return project_world(point) - Vector2(18, 15)


func screen_position(index: int) -> Vector2:
	return project_world(displayed_world(index))


func project_cell(cell: Vector2i) -> Vector2:
	return project_world(world_cell(cell))


func focus_selected(immediately: bool = false) -> void:
	if battle.valid_unit(selected) and visible_to_player(selected):
		orbit.focus_world(displayed_world(selected), immediately)


func _bind_actor(index: int) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var actor: Node2D = actors[index]
	actor.render_ground_shadow = false
	actor.reparent(vp, false)
	actor.position = Vector2(128, 208)
	actor_views[index] = vp
	var billboard := Sprite3D.new()
	billboard.texture = vp.get_texture()
	billboard.pixel_size = 0.02
	billboard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	billboard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	billboard.shaded = false
	billboard.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	billboard.alpha_scissor_threshold = 0.06
	billboard.no_depth_test = false
	world_root.add_child(billboard)
	billboards[index] = billboard
	var shadow := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = 0.30
	disk.bottom_radius = 0.30
	disk.height = 0.003
	disk.radial_segments = 24
	shadow.mesh = disk
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.01, 0.01, 0.02, 0.4)
	shadow.material_override = material
	world_root.add_child(shadow)
	shadows[index] = shadow


func _process(delta: float) -> void:
	if not is_instance_valid(orbit.camera) or not orbit.camera.is_inside_tree():
		return
	super._process(delta)
	_sync_spatial()
	_sync_effects()
	spatial_overlay.queue_redraw()
	camera_hint.text = (
		(
			"CÂMERA %.0f° · zoom %.2f×\nDireito: girar · Roda: zoom\n"
			+ "Meio: foco · Home: restaurar\nF: herói · F2: 2D/2.5D"
		)
		% [orbit.yaw_degrees, 1.0 / orbit.zoom_factor]
	)


func _sync_spatial() -> void:
	for i in actors:
		if not actor_views.has(i):
			_bind_actor(i)
		actors[i].position = Vector2(128, 208)
		var position3d := displayed_world(i)
		billboards[i].position = position3d + orbit.camera.global_basis.y * 1.6
		billboards[i].visible = visible_to_player(i)
		shadows[i].position = position3d + Vector3(0, 0.022, 0)
		shadows[i].visible = visible_to_player(i) and visual_units[i].hp > 0
	lava_surface.update_zones(visual_fire, Battle.WALLS)
	_sync_smoke()
	_sync_spirit()


func _sync_spirit() -> void:
	if not is_instance_valid(spirit):
		if is_instance_valid(spirit_view):
			spirit_view.queue_free()
			spirit_view = null
		if is_instance_valid(spirit_billboard):
			spirit_billboard.queue_free()
			spirit_billboard = null
		return
	if not is_instance_valid(spirit_view):
		spirit_view = SubViewport.new()
		spirit_view.size = Vector2i(256, 256)
		spirit_view.transparent_bg = true
		spirit_view.disable_3d = true
		spirit_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(spirit_view)
		spirit.reparent(spirit_view, false)
		spirit_billboard = Sprite3D.new()
		spirit_billboard.texture = spirit_view.get_texture()
		spirit_billboard.pixel_size = 0.02
		spirit_billboard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spirit_billboard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		spirit_billboard.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		spirit_billboard.alpha_scissor_threshold = 0.03
		world_root.add_child(spirit_billboard)
	spirit.position = Vector2(128, 208)
	spirit_billboard.position = (
		world_cell(spirit_cell) + orbit.camera.global_basis.y * 1.6 + Vector3.UP * 0.5
	)


func _sync_smoke() -> void:
	for key in smoke_cards.keys():
		if int(key) >= visual_smoke.size():
			smoke_cards[key].queue_free()
			smoke_cards.erase(key)
	for i in visual_smoke.size():
		if not smoke_cards.has(i):
			var cloud := Node3D.new()
			for part in 9:
				var mist := MeshInstance3D.new()
				var sphere := SphereMesh.new()
				sphere.radius = 0.8
				sphere.height = 1.7
				sphere.radial_segments = 12
				sphere.rings = 6
				mist.mesh = sphere
				var material := StandardMaterial3D.new()
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.albedo_color = Color(0.23, 0.21, 0.25, 0.34)
				mist.material_override = material
				var angle := part * TAU / 8
				mist.position = Vector3(
					sin(angle) * (1.7 if part < 8 else 0),
					0.7,
					cos(angle) * (1.7 if part < 8 else 0)
				)
				cloud.add_child(mist)
			world_root.add_child(cloud)
			smoke_cards[i] = cloud
		smoke_cards[i].position = world_cell(visual_smoke[i].cell)
		smoke_cards[i].rotation.y = sin(elapsed * 0.3) * 0.07


func _apply_visual(event: Dictionary) -> void:
	if event.kind == "spirit":
		spirit_cell = event.get("cell", Vector2i(5, 4))
	var before: int = effects.active.size()
	super._apply_visual(event)
	for i in range(before, effects.active.size()):
		effects.active[i].spatial_event = event.duplicate(true)
	_sync_effects()


func _sync_effects() -> void:
	for effect in effects.active:
		if not effect.has("spatial_event"):
			continue
		var event: Dictionary = effect.spatial_event
		var source: int = event.get("source", -1)
		var target: int = event.get("target", -1)
		var origin: Vector3 = (
			displayed_world(source) + Vector3(0, 0.65, 0)
			if battle.valid_unit(source)
			else world_cell(event.get("cell", Vector2i.ZERO))
		)
		var destination: Vector3 = (
			displayed_world(target) + Vector3(0, 0.65, 0)
			if battle.valid_unit(target)
			else world_cell(event.get("cell", Vector2i.ZERO))
		)
		effect.from = project_world(origin)
		effect.to = project_world(destination)
		if event.has("area_centers"):
			var centers: Array[Vector2] = []
			for direction in (
				Battle.DIRECTIONS + [Vector2i.ZERO]
				if event.get("radius", 1) > 0
				else [Vector2i.ZERO]
			):
				var cell: Vector2i = event.cell + direction
				if battle.inside(cell):
					centers.append(project_cell(cell))
			effect.area_centers = centers


func _input(event: InputEvent) -> void:
	# O botão pode ser solto sobre o HUD, onde o GUI consome unhandled_input.
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbit.rotating = false
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			orbit.panning = false


func _unhandled_input(event: InputEvent) -> void:
	if orbit.handle_control(event):
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func pointer_cell(pointer: Vector2) -> Vector2i:
	if not orbit.camera.is_inside_tree():
		return Vector2i(-1, -1)
	var index := pick_unit(pointer)
	if index >= 0:
		return visual_units[index].cell
	return pick_ground(pointer)


func pick_ground(pointer: Vector2) -> Vector2i:
	var origin := orbit.camera.project_ray_origin(pointer)
	var direction := orbit.camera.project_ray_normal(pointer)
	if absf(direction.y) < 0.0001:
		return Vector2i(-1, -1)
	var point := origin + direction * (-origin.y / direction.y)
	var cell := Vector2i(roundi(point.x + 7), roundi(point.z + 4))
	if not battle.inside(cell) or cell in Battle.WALLS:
		return Vector2i(-1, -1)
	var query := PhysicsRayQueryParameters3D.create(origin, point + direction * 0.01, 1)
	if not world_root.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return Vector2i(-1, -1)
	return cell


func pick_unit(pointer: Vector2) -> int:
	var front: Array = billboards.keys()
	front.sort_custom(
		func(a: int, b: int):
			return (
				orbit.camera.global_position.distance_squared_to(displayed_world(a))
				< orbit.camera.global_position.distance_squared_to(displayed_world(b))
			)
	)
	# La base pequeña conserva acceso a aliados/lacaios agrupados, sin mover sus sprites.
	for index in front:
		if not _pickable(index):
			continue
		var base := screen_position(index)
		if (
			Vector2((pointer.x - base.x) / 11.0, (pointer.y - base.y) / 7.0).length_squared() <= 1.0
			and _unoccluded(index)
		):
			return index
	for index in front:
		if not _pickable(index) or not _unoccluded(index):
			continue
		var sprite: AnimatedSprite2D = actors[index].sprite
		var texture2d: Texture2D = sprite.sprite_frames.get_frame_texture(
			sprite.animation, sprite.frame
		)
		var anchor := project_world(billboards[index].position)
		var pixel_scale: float = (
			project_world(billboards[index].position + orbit.camera.global_basis.x * 0.02)
			. distance_to(anchor)
		)
		var view_point := (pointer - anchor) / pixel_scale + Vector2(128, 128)
		var local_point: Vector2 = (
			(view_point - Vector2(128, 208)) / actors[index].scale.x
			- sprite.position
			- sprite.offset
			+ Vector2(56, 64)
		)
		if sprite.flip_h:
			local_point.x = texture2d.get_width() - local_point.x
		if (
			local_point.x >= 0
			and local_point.y >= 0
			and local_point.x < texture2d.get_width()
			and local_point.y < texture2d.get_height()
		):
			if texture2d.get_image().get_pixelv(Vector2i(local_point)).a > 0.12:
				return index
	return -1


func _pickable(index: int) -> bool:
	return battle.units[index].hp > 0 and visible_to_player(index)


func _unoccluded(index: int) -> bool:
	var point := displayed_world(index) + Vector3(0, 0.6, 0)
	var query := PhysicsRayQueryParameters3D.create(orbit.camera.global_position, point, 1)
	return world_root.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func reset_visuals() -> void:
	for object in (
		billboards.values() + shadows.values() + actor_views.values() + smoke_cards.values()
	):
		object.queue_free()
	billboards.clear()
	shadows.clear()
	actor_views.clear()
	smoke_cards.clear()
	super.reset_visuals()
	if is_instance_valid(orbit.camera) and orbit.camera.is_inside_tree():
		_sync_spatial()


func paint_overlays(_canvas: Node2D) -> void:
	pass
