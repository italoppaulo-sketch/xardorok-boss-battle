extends RefCounted
## Duração em turnos do portador, incluindo o turno atual quando aplicado em si.
const DEFINITIONS := {
	"fire_shield":
	{"name": "Escudo de Fogo −40%", "short": "EF", "negative": false, "color": "ffd47b"},
	"fire_aura": {"name": "Aura de Fogo", "short": "AF", "negative": false, "color": "ff762d"},
	"burning": {"name": "Queimadura", "short": "Q", "negative": true, "color": "ff905a"},
	"frozen": {"name": "Congelamento", "short": "G", "negative": true, "color": "93e7fa"},
	"rooted": {"name": "Enraizamento", "short": "R", "negative": true, "color": "8bdb78"},
	"silenced": {"name": "Silêncio", "short": "S", "negative": true, "color": "a5a1e8"},
	"defense": {"name": "Defesa +35%", "short": "D", "negative": false, "color": "93e7fa"},
	"attack": {"name": "Ataque +35%", "short": "A", "negative": false, "color": "f9d978"},
	"evasion": {"name": "Esquiva +30%", "short": "E", "negative": false, "color": "b893ef"},
	"illusion": {"name": "Duplicata", "short": "I", "negative": false, "color": "79caff"},
	"flight": {"name": "Voo", "short": "V", "negative": false, "color": "f9d978"},
	"ice_skin": {"name": "Pele Glacial", "short": "P", "negative": false, "color": "93e7fa"},
	"ice_hammer": {"name": "Martelo Glacial", "short": "M", "negative": false, "color": "93e7fa"},
	"giant": {"name": "Gigante", "short": "T", "negative": false, "color": "93e7fa"}
}


static func apply(unit: Dictionary, id: String, duration: int) -> bool:
	if unit.hp <= 0 or not DEFINITIONS.has(id) or duration <= 0:
		return false
	unit.statuses[id] = maxi(unit.statuses.get(id, 0), duration)
	return true


static func has(unit: Dictionary, id: String) -> bool:
	return unit.statuses.get(id, 0) > 0


static func expire(unit: Dictionary) -> Array[String]:
	var removed: Array[String] = []
	for id in unit.statuses.keys():
		unit.statuses[id] -= 1
		if unit.statuses[id] <= 0:
			unit.statuses.erase(id)
			removed.append(id)
	return removed


static func dispel(unit: Dictionary, negative: bool) -> int:
	var removed := 0
	for id in unit.statuses.keys():
		if DEFINITIONS[id].negative == negative:
			unit.statuses.erase(id)
			removed += 1
	return removed


static func describe(unit: Dictionary) -> String:
	var labels: PackedStringArray = []
	for id in unit.statuses:
		labels.append("%s (%d)" % [DEFINITIONS[id].name, unit.statuses[id]])
	return " · ".join(labels) if not labels.is_empty() else "Sem estados alterados"
