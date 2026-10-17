extends "res://scripts/main.gd"
## Experimento isolado: usa integralmente o controlador e o motor aprovados.
const Hybrid = preload("res://scripts/camera/hybrid_arena.gd")


func _init() -> void:
	arena = Hybrid.new()
