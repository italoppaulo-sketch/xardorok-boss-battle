extends Camera2D
## Pure 2D view transform. Combat cells and CanvasLayer HUD never move.
const DEFAULT_CENTER := Vector2(600, 350)
@export var minimum_zoom := 0.85
@export var maximum_zoom := 1.8
@export var zoom_step := 0.12
@export var smoothing_speed := 14.0
var target_zoom := 1.0
var dragging := false


func _ready() -> void:
	name = "TacticalZoom"
	position = DEFAULT_CENTER
	position_smoothing_enabled = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	make_current()


func _process(delta: float) -> void:
	var factor := 1.0 - exp(-smoothing_speed * delta)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, factor)
	if absf(zoom.x - target_zoom) < 0.0005:
		zoom = Vector2.ONE * target_zoom


func change_zoom(direction: float) -> void:
	target_zoom = clampf(target_zoom + direction * zoom_step, minimum_zoom, maximum_zoom)


func reset_view() -> void:
	target_zoom = 1.0
	zoom = Vector2.ONE
	position = DEFAULT_CENTER
	dragging = false
	reset_smoothing()
	force_update_scroll()


func focus_world(point: Vector2) -> void:
	position = point
	_clamp_position()
	force_update_scroll()


func _clamp_position() -> void:
	position.x = clampf(position.x, 220, 980)
	position.y = clampf(position.y, 180, 520)


func _input(event: InputEvent) -> void:
	# Release must be caught even when the pointer is now over the fixed HUD.
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_MIDDLE
		and not event.pressed
	):
		dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif (
			event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
		):
			change_zoom(1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom.x
		_clamp_position()
		get_viewport().set_input_as_handled()
