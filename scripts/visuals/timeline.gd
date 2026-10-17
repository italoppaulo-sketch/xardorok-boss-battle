extends RefCounted
## Agenda só a apresentação. Nunca chama as regras de dano ou o sistema de ações.
var pending: Array[Dictionary] = []
var clock := 0.0
var duration := 0.0
var playing := false


func begin() -> void:
	pending.clear()
	clock = 0.0
	duration = 0.0
	playing = false


func add(at: float, event: Dictionary) -> void:
	pending.append({"at": at, "event": event})
	duration = maxf(duration, at + 0.25)
	playing = true


func finish_build(at: float) -> void:
	duration = maxf(duration, at)
	pending.sort_custom(func(a: Dictionary, b: Dictionary): return a.at < b.at)


func advance(delta: float) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	if not playing:
		return ready
	clock += delta
	while not pending.is_empty() and pending[0].at <= clock:
		ready.append(pending.pop_front().event)
	if clock >= duration and pending.is_empty():
		playing = false
	return ready
