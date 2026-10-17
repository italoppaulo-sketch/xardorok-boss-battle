extends Node2D
var arena: Node2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if arena == null:
		return
	arena.paint_overlays(self)
