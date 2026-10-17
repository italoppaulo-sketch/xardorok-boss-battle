extends RefCounted
## Ponto de integração futura: Dalamud é um espírito, sem corpo ou unidade no tabuleiro.
const IDENTITY := {"name": "Dalamud", "nature": "spirit", "ally": true}


static func grant(battle: RefCounted, duration: int = 2) -> void:
	for i in 5:
		battle.apply_status(i, "attack", duration)
		battle.apply_status(i, "defense", duration)
