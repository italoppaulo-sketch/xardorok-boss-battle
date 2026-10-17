extends RefCounted
## Parâmetros provisórios para a batalha inicial.


static func create_units() -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var names := ["Grosso", "Kodokami", "Cassandra", "Thomas", "Thuxil", "Xardorok"]
	var health := [150, 95, 85, 95, 90, 520]
	var damage := [32, 36, 27, 30, 28, 30]
	var reach := [1, 1, 6, 7, 5, 1]
	var cells := [
		Vector2i(2, 2),
		Vector2i(2, 4),
		Vector2i(1, 6),
		Vector2i(3, 6),
		Vector2i(4, 4),
		Vector2i(12, 4)
	]
	var colors := [
		Color("78dce8"),
		Color("b191e8"),
		Color("577be8"),
		Color("86bd76"),
		Color("cf6868"),
		Color("f3853c")
	]
	for i in names.size():
		units.append(
			{
				"name": names[i],
				"hp": health[i],
				"max_hp": health[i],
				"damage": damage[i],
				"range": reach[i],
				"cell": cells[i],
				"color": colors[i],
				"enemy": i == 5,
				"move": 5,
				"actions": 1
			}
		)
	return units
