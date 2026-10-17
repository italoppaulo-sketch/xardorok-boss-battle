extends RefCounted
## Catálogo independente do motor e da apresentação. Distâncias em passos Manhattan.
const DATA := {
	"basic":
	{
		"name": "Ataque básico",
		"target": "enemy",
		"range": -1,
		"power": -1,
		"element": "physical",
		"color": "e5d1a1",
		"description": "Ataque com a arma. Pode causar crítico ou ser esquivado."
	},
	"skin":
	{
		"name": "Pele Glacial",
		"target": "self",
		"bonus": true,
		"mana": 10,
		"cooldown": 3,
		"duration": 3,
		"color": "93e7fa",
		"description": "3 turnos: reduz dano em 35% e devolve 8 de gelo em golpes de contato."
	},
	"hammer":
	{
		"name": "Martelo Glacial",
		"target": "self",
		"bonus": true,
		"mana": 8,
		"cooldown": 2,
		"duration": 3,
		"color": "93e7fa",
		"description": "3 turnos: +12 de gelo por golpe; 35% de congelar por 1 turno."
	},
	"double":
	{
		"name": "Ataque Duplo",
		"target": "enemy",
		"range": 1,
		"power": 23,
		"hits": 2,
		"element": "physical",
		"color": "93e7fa",
		"description": "Dois golpes de 23 com uma única ação. Combina com martelo e forma gigante."
	},
	"giant":
	{
		"name": "Forma Gigante",
		"target": "self",
		"bonus": true,
		"mana": 15,
		"cooldown": 4,
		"duration": 2,
		"color": "93e7fa",
		"description": "2 turnos: +35% de dano e +1 de alcance físico. Mantém a célula ocupada."
	},
	"unarmed":
	{
		"name": "Ataque Desarmado Duplo",
		"target": "enemy",
		"range": 1,
		"power": 23,
		"hits": 2,
		"element": "physical",
		"color": "b893ef",
		"description": "Dois golpes rápidos de 23 com uma ação principal."
	},
	"dodge":
	{
		## Catálogo independente do motor e da apresentação. Distâncias em passos Manhattan.
		"name": "Esquiva Elevada",
		"target": "self",
		"bonus": true,
		"mana": 10,
		"cooldown": 2,
		"duration": 2,
		"color": "b893ef",
		"description": "2 turnos: +30 pontos percentuais de esquiva física, além dos 25% naturais."
	},
	"fushigiri":
	{
		"name": "Fushigiri",
		"target": "enemy",
		"range": 2,
		"power": 125,
		"element": "shadow",
		"mana": 20,
		"hp_cost": 24,
		"cooldown": 3,
		"color": "bc7cff",
		"description": "Corte sombrio de 125. Custa 24 HP além de mana; exige mais de 24 HP."
	},
	"root_arrow":
	{
		"name": "Flecha Enraizante",
		"target": "enemy",
		"range": 7,
		"power": 25,
		"element": "physical",
		"mana": 10,
		"status": "rooted",
		"duration": 1,
		"color": "8bdb78",
		"description": "25 de dano. Impede movimento durante o próximo turno do alvo."
	},
	"ice_arrow":
	{
		"name": "Flecha de Gelo",
		"target": "enemy",
		"range": 7,
		"power": 38,
		"element": "ice",
		"mana": 16,
		"radius": 1,
		"color": "93e7fa",
		"description": "38 de gelo no alvo e nos inimigos a até 1 passo. Não atinge aliados."
	},
	"energy_arrow":
	{
		"name": "Flecha Energizada",
		"target": "enemy",
		"range": 8,
		"power": 85,
		"element": "lightning",
		"mana": 22,
		"cooldown": 2,
		"color": "f9d978",
		"description": "85 de energia em um alvo; projétil dourado. Recarga de 2 rodadas."
	},
	"flight":
	{
		"name": "Botas Mágicas",
		"target": "self",
		"bonus": true,
		"mana": 10,
		"cooldown": 3,
		"duration": 2,
		"color": "f9d978",
		"description":
		(
			"2 turnos: +2 passos e cruza pilares/unidades. "
			+ "Deve pousar em célula livre; ainda recebe ataques."
		)
	},
	"antispell":
	{
		"name": "Antispell",
		"target": "ground",
		"range": 9,
		"mana": 12,
		"magic": true,
		"los": false,
		"color": "9cbfff",
		"description":
		(
			"Clique na fumaça ou marca de meteoro para dissipar; "
			+ "remove debuffs de aliado ou buffs de inimigo."
		)
	},
	"heal":
	{
		"name": "Cura",
		"target": "ally",
		"range": 7,
		"power": 60,
		"mana": 14,
		"magic": true,
		"color": "87f2bc",
		"description": "Recupera até 60 HP de um aliado vivo, sem exceder seu máximo."
	},
	"purple_fire":
	{
		"name": "Raio de Fogo Roxo",
		"target": "enemy",
		"range": 7,
		"power": 68,
		"element": "violet",
		"mana": 18,
		"magic": true,
		"color": "d48bff",
		"description": "68 de fogo arcano violeta; distinto do fogo comum e de sua resistência."
	},
	"illusion":
	{
		"name": "Duplicata Ilusória",
		"target": "self",
		"bonus": true,
		"mana": 10,
		"duration": 2,
		"magic": true,
		"color": "79caff",
		"description":
		"Ação bônus. Próxima habilidade de dano garante crítico; imagem dura até 2 turnos."
	},
	"chain":
	{
		"name": "Raio Azul Encadeado",
		"target": "enemy",
		"range": 7,
		"power": 50,
		"element": "lightning",
		"mana": 20,
		"magic": true,
		"bounces": 4,
		"jump": 3,
		"color": "69cfff",
		"description":
		"50 de dano em até 4 inimigos. Cada salto exige visão e distância de até 3 passos."
	},
	"silence":
	{
		"name": "Silêncio",
		"target": "enemy",
		"range": 7,
		"mana": 12,
		"magic": true,
		"status": "silenced",
		"duration": 1,
		"color": "69cfff",
		"description":
		"Impede a próxima conjuração do alvo. Não bloqueia ataques físicos nem a aura de fogo."
	},
	"smoke":
	{
		"name": "Bolha de Fumaça",
		"target": "self",
		"magic": true,
		"cooldown": 3,
		"color": "9d94a7",
		"description":
		"Fumaça por 2 rodadas. Bloqueia visão entre interior/exterior e através da área."
	},
	"meteors":
	{
		"name": "Chuva de Meteoros",
		"target": "ground",
		"range": 20,
		"magic": true,
		"los": false,
		"cooldown": 3,
		"power": 40,
		"radius": 1,
		"color": "ff905a",
		"description":
		"Marca 2 áreas de raio 1; impactos só na próxima fase inimiga. Antispell cancela uma marca."
	},
	"summon":
	{
		"name": "Guerreiros de Cinzas",
		"target": "self",
		"magic": true,
		"cooldown": 4,
		"color": "ff905a",
		"description": "Invoca até 2 lacaios (máximo 3 vivos). Agem a partir da próxima rodada."
	}
}
const LOADOUTS := [
	["skin", "hammer", "double", "giant"],
	["unarmed", "dodge", "fushigiri"],
	["antispell", "heal", "purple_fire"],
	["root_arrow", "ice_arrow", "energy_arrow", "flight"],
	["illusion", "chain", "silence"],
	["smoke", "meteors", "summon"]
]


static func get_skill(id: String) -> Dictionary:
	return DATA.get(id, {}).duplicate(true)


static func loadout(index: int) -> Array:
	return LOADOUTS[index].duplicate() if index < LOADOUTS.size() else []
