extends SceneTree
const Actor := preload("res://scripts/visuals/sprite_actor.gd")
const Victory := preload("res://scripts/visuals/victory_sequence.gd")
const Effects := preload("res://scripts/visuals/effects_renderer.gd")


class MockArena:
	extends Node2D
	var positions := {5: Vector2(600, 300)}
	var actors := {}

	func center(_cell: Vector2i) -> Vector2:
		return Vector2(600, 300)


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var checks := 0
	var actor := Actor.new()
	root.add_child(actor)
	actor.configure(5)
	var unit := {"hp": 900, "statuses": {"fire_aura": 3, "fire_shield": 2}, "boss_phase": 1}
	actor.sync(unit, false)
	assert(actor.fire_overlay.visible and actor.fire_aura and actor.fire_shield)
	checks += 1
	actor.electric_pulse()
	assert(actor.electric_until > actor.clock)
	checks += 1
	unit.statuses.clear()
	actor.sync(unit, false)
	assert(not actor.fire_overlay.visible)
	checks += 1
	var arena := MockArena.new()
	root.add_child(arena)
	arena.actors[5] = actor
	var victory := Victory.new()
	root.add_child(victory)
	victory.configure(arena, RefCounted.new())
	victory.start()
	assert(victory.is_playing() and victory.canvas.visible)
	checks += 1
	victory.elapsed = 1.6
	victory._update_visuals()
	assert(victory.crown.position.y > victory.crown_origin.y)
	checks += 1
	victory.skip()
	assert(victory.is_finished() and not victory.is_playing())
	assert(actor.sprite.speed_scale == 1.0)
	checks += 2
	victory.reset()
	assert(not victory.canvas.visible and not victory.is_finished())
	checks += 1
	var effects := Effects.new()
	root.add_child(effects)
	effects.add_event(
		{"kind": "link", "source": 4, "target": 5}, Vector2(400, 300), Vector2(600, 300)
	)
	assert(effects.active.size() == 1 and effects.textures.has("electric"))
	checks += 1
	await process_frame
	print("PRESENTATION5: %d checks passed" % checks)
	quit(0)
