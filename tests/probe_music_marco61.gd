extends SceneTree
var node: Node
var elapsed := 0.0
var last_second := -1


func _initialize() -> void:
	call_deferred("start")


func start() -> void:
	node = load("res://scripts/audio/battle_audio.gd").new()
	node.persist_settings = false
	root.add_child(node)
	node.restart()


func _process(delta: float) -> bool:
	if node == null:
		return false
	elapsed += delta
	if elapsed >= 3 and node.phase_target == 0:
		node.on_visual({"kind": "phase"})
	var tick := int(elapsed * 4)
	if tick != last_second:
		last_second = tick
		var data := []
		for p in node.music:
			data.append({"pos": p.get_playback_position(), "db": p.volume_db, "playing": p.playing})
		print(JSON.stringify({"t": elapsed, "players": data}))
	if elapsed > 7:
		node.shutdown()
		quit()
	return false
