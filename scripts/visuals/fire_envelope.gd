extends Node2D
## Camada de fogo PNG sobre o sprite; a ausência dos estados apaga o efeito.
var aura := false
var shield := false
var clock := 0.0
var aura_texture: Texture2D = preload("res://assets/effects/marco5/aura.png")
var shield_texture: Texture2D = preload("res://assets/effects/marco5/shield.png")


func set_effects(aura_active: bool, shield_active: bool) -> void:
	aura = aura_active
	shield = shield_active
	visible = aura or shield


func _process(delta: float) -> void:
	clock += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var frame := int(clock * 9) % 4
	var source := Rect2(frame * 96, 0, 96, 96)
	if aura:
		draw_texture_rect_region(
			aura_texture, Rect2(-48, -29, 96, 48), source, Color(1, 1, 1, 0.95)
		)
		for i in 7:
			var phase := fmod(clock * 0.7 + i * 0.13, 1.0)
			var at := Vector2(sin(i * 2.4 + clock) * (20 + i * 2), -8 - phase * 55)
			draw_rect(Rect2(at, Vector2(2, 2)), Color(1, 0.48 + phase * 0.3, 0.1, 1 - phase))
	if shield:
		draw_texture_rect_region(
			shield_texture, Rect2(-39, -95, 78, 104), source, Color(1, 1, 1, 0.85)
		)
