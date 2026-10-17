extends Node2D
## Apresentação de um combatente. Não calcula dano, ações ou deslocamento lógico.
const NAMES := ["grosso", "kodokami", "cassandra", "thomas", "thuxil", "xardorok_marco4"]
const FireEnvelope := preload("res://scripts/visuals/fire_envelope.gd")
var sprite := AnimatedSprite2D.new()
var duplicate_sprite := AnimatedSprite2D.new()
var identity := ""
var actor_index := 0
var locked_until := 0.0
var clock := 0.0
var was_dead := false
var is_ready := false
var desired_scale := 1.0
var floating := false
var walk_active := false
var idle_height := 64.0
var flash_until := 0.0
var ice_skin := false
var ice_hammer := false
var ice_texture: Texture2D
var enraged := false
var hit_images := {}
var fire_aura := false
var fire_shield := false
var electric_until := 0.0
var fire_overlay: Node2D


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(duplicate_sprite)
	add_child(sprite)
	fire_overlay = FireEnvelope.new()
	fire_overlay.z_index = 2
	add_child(fire_overlay)
	sprite.offset = Vector2(0, -54)
	duplicate_sprite.offset = Vector2(-24, -54)
	duplicate_sprite.modulate = Color(0.4, 0.8, 1, 0.38)
	duplicate_sprite.visible = false


func configure(index: int, forced_identity: String = "") -> void:
	actor_index = index
	identity = (
		forced_identity
		if not forced_identity.is_empty()
		else (NAMES[index] if index < 6 else "lacaio")
	)
	var path := "res://assets/characters/%s/animations.tres" % identity
	if not ResourceLoader.exists(path):
		push_error("Sprite ausente: " + identity)
		return
	sprite.sprite_frames = load(path)
	duplicate_sprite.sprite_frames = sprite.sprite_frames
	var metadata_path := "res://assets/characters/%s/atlas.json" % identity
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	idle_height = float(metadata.get("idle_height", 64))
	if index == 3 or identity == "dalamud":
		sprite.sprite_frames = sprite.sprite_frames.duplicate()
		sprite.sprite_frames.add_animation("hover")
		sprite.sprite_frames.set_animation_loop("hover", true)
		sprite.sprite_frames.set_animation_speed("hover", 5)
		for frame in 4:
			sprite.sprite_frames.add_frame(
				"hover", sprite.sprite_frames.get_frame_texture("special", frame)
			)
		duplicate_sprite.sprite_frames = sprite.sprite_frames
	floating = identity == "dalamud"
	ice_texture = load("res://assets/effects/ice/atlas.png")
	is_ready = true
	sprite.play("idle")
	duplicate_sprite.play("idle")


func animate(animation: String, duration: float = 0.55) -> void:
	if not is_ready or was_dead:
		return
	if sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)
		locked_until = clock + duration


func on_damage(dead: bool) -> void:
	if not is_ready:
		return
	if dead:
		was_dead = true
		sprite.play("death")
		if actor_index == 5:
			sprite.speed_scale = 0.35
		duplicate_sprite.visible = false
		locked_until = INF
	else:
		flash_until = clock + 0.14
		animate("hit", 0.25)


func sync(unit: Dictionary, moving: bool) -> void:
	if not is_ready:
		return
	walk_active = moving
	fire_aura = unit.statuses.has("fire_aura") and unit.hp > 0
	fire_shield = unit.statuses.has("fire_shield") and unit.hp > 0
	fire_overlay.set_effects(fire_aura, fire_shield)
	enraged = unit.get("boss_phase", 1) == 2 and actor_index == 5
	ice_skin = unit.statuses.has("ice_skin")
	ice_hammer = unit.statuses.has("ice_hammer")
	floating = unit.statuses.has("flight") or identity == "dalamud"
	desired_scale = 1.6 if unit.statuses.has("giant") else (1.2 if actor_index == 5 else 1.0)
	if unit.hp <= 0 and not was_dead:
		on_damage(true)
	duplicate_sprite.visible = unit.statuses.has("illusion") and not was_dead
	if duplicate_sprite.visible:
		duplicate_sprite.animation = sprite.animation
		duplicate_sprite.frame = sprite.frame
	if unit.hp > 0 and clock >= locked_until:
		var idle := "hover" if floating else ("walk" if moving else "idle")
		if sprite.animation != idle or not sprite.is_playing():
			sprite.play(idle)
	var color := Color(1.2, 0.78, 0.58) if enraged else Color.WHITE
	if ice_skin:
		color = Color(0.65, 0.88, 1.15)
	if unit.statuses.has("frozen"):
		color = Color(0.6, 0.85, 1)
	if clock < flash_until:
		color = Color(2, 1.3, 1.3)
	if clock < electric_until:
		color = Color(0.65, 1.6, 2.3)
	sprite.modulate = color


func _process(delta: float) -> void:
	clock += delta
	scale = scale.lerp(Vector2.ONE * desired_scale, minf(1, delta * 8))
	var lift := -7.0 + sin(clock * 3) * 2 if floating else 0.0
	sprite.position.y = lift
	duplicate_sprite.position.y = lift + sin(clock * 2) * 2
	queue_redraw()


func _draw() -> void:
	if identity != "dalamud":
		draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 19, Color(0.02, 0.025, 0.04, 0.45))
		draw_set_transform(Vector2.ZERO)

	if ice_texture != null and not was_dead:
		var frame := int(clock * 5) % 4
		if ice_skin:
			draw_texture_rect_region(
				ice_texture,
				Rect2(-28, -65, 56, 64),
				Rect2(frame * 96, 0, 96, 96),
				Color(0.75, 0.95, 1, 0.25)
			)
		if ice_hammer:
			var side := -1 if sprite.flip_h else 1
			draw_texture_rect_region(
				ice_texture,
				Rect2(side * 18 - 15, -48, 30, 38),
				Rect2(frame * 96, 0, 96, 96),
				Color(0.75, 0.95, 1, 0.55)
			)


func contains_point(global_point: Vector2) -> bool:
	if not visible or not is_ready or was_dead:
		return false
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var point: Vector2 = (
		sprite.to_local(global_point) - sprite.offset + Vector2(texture.get_size()) * 0.5
	)
	var pixel := Vector2i(floori(point.x), floori(point.y))
	if (
		pixel.x < 0
		or pixel.y < 0
		or pixel.x >= texture.get_width()
		or pixel.y >= texture.get_height()
	):
		return false
	if sprite.flip_h:
		pixel.x = texture.get_width() - 1 - pixel.x
	var key := "%s:%d" % [sprite.animation, sprite.frame]
	if not hit_images.has(key):
		hit_images[key] = texture.get_image()
	return hit_images[key].get_pixelv(pixel).a > 0.2


func electric_pulse() -> void:
	electric_until = clock + 0.22


func extinguish() -> void:
	fire_aura = false
	fire_shield = false
	fire_overlay.set_effects(false, false)
