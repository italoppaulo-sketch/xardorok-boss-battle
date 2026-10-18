extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	for frame in 120:
		await process_frame
	scene.audio.shutdown()
	await create_timer(.15).timeout
	scene.queue_free()
	await process_frame
	print("Marco6 startup: 120 frames, graceful audio shutdown")
	quit()
