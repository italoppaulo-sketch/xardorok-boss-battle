extends RefCounted


## Iniciativa fixa explícita; empates são resolvidos pelo índice estável da unidade.
static func order(units: Array[Dictionary], round_number: int) -> Array[int]:
	var result: Array[int] = []
	for i in units.size():
		if units[i].get("spawn_round", 0) < round_number:
			result.append(i)
	result.sort_custom(
		func(a: int, b: int):
			var left: int = units[a].initiative
			var right: int = units[b].initiative
			return a < b if left == right else left > right
	)
	return result
