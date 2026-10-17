# gdlint: disable=max-returns
extends Node3D
## Orbita horizontal real. Nenhuma transformação de Camera2D ou mudança de regras.
signal changed
signal focus_requested
var camera := Camera3D.new()
var yaw_degrees := 0.0
var target_yaw := 0.0
var zoom_factor := 1.0
var target_zoom := 1.0
var focus := Vector3(0, -1.0, 0)
var target_focus := Vector3(0, -1.0, 0)
var minimum_yaw := -90.0
var maximum_yaw := 90.0
var minimum_zoom := 0.62
var maximum_zoom := 1.32
var drag_sensitivity := 0.35
var zoom_step := 0.10
var rotating := false
var panning := false
var controls_enabled := true


func _ready() -> void:
	camera.fov = 40
	camera.near = 0.1
	camera.far = 150
	add_child(camera)
	camera.current = true
	set_process_unhandled_input(false)
	snap()


func set_orbit(degrees: float, zoom: float = 1.0, immediately: bool = false) -> void:
	target_yaw = clampf(degrees, minimum_yaw, maximum_yaw)
	target_zoom = clampf(zoom, minimum_zoom, maximum_zoom)
	if immediately:
		snap()


func focus_world(point: Vector3, immediately: bool = false) -> void:
	target_focus = Vector3(clampf(point.x, -7, 7), -1.0, clampf(point.z, -4, 4))
	if immediately:
		snap()


func reset_view(immediately: bool = false) -> void:
	target_yaw = 0
	target_zoom = 1
	target_focus = Vector3(0, -1.0, 0)
	if immediately:
		snap()


func snap() -> void:
	yaw_degrees = target_yaw
	zoom_factor = target_zoom
	focus = target_focus
	_apply_camera()


func _process(delta: float) -> void:
	var weight := 1.0 - exp(-16 * delta)
	yaw_degrees = lerpf(yaw_degrees, target_yaw, weight)
	zoom_factor = lerpf(zoom_factor, target_zoom, weight)
	focus = focus.lerp(target_focus, weight)
	_apply_camera()


func _apply_camera() -> void:
	var angle := deg_to_rad(yaw_degrees)
	# Enquadramento adapta o comprimento projetado da plataforma; zoom continua limitado.
	var radius := (19.5 + absf(sin(angle)) * 7.5) * zoom_factor
	var elevation := deg_to_rad(56)
	camera.position = (
		focus
		+ Vector3(sin(angle) * cos(elevation), sin(elevation), cos(angle) * cos(elevation)) * radius
	)
	camera.look_at(focus, Vector3.UP)
	changed.emit()


func handle_control(event: InputEvent) -> bool:
	if not controls_enabled:
		return false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
		elif (
			event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
		):
			target_zoom = clampf(
				(
					target_zoom
					+ (-zoom_step if event.button_index == MOUSE_BUTTON_WHEEL_UP else zoom_step)
				),
				minimum_zoom,
				maximum_zoom
			)
		else:
			return false
		return true
	if event is InputEventMouseMotion and (rotating or panning):
		if rotating:
			target_yaw = clampf(
				target_yaw - event.relative.x * drag_sensitivity, minimum_yaw, maximum_yaw
			)
		if panning:
			var side := camera.global_basis.x
			var forward := Vector3(side.z, 0, -side.x)
			focus_world(
				target_focus - side * event.relative.x * 0.018 + forward * event.relative.y * 0.018
			)
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_HOME:
			reset_view()
		elif event.keycode == KEY_F:
			focus_requested.emit()
		else:
			return false
		return true

	return false
