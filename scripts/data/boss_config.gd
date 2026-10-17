extends RefCounted
## Única tabela de ajustes do chefe. Não muda parâmetros aprovados dos heróis.
const MAX_HP := 900
const PHYSICAL_DAMAGE := 30
const ARMOR_DAMAGE_MULTIPLIER := 0.72
const RESISTANCES := {
	"physical": 0.30, "shadow": 0.20, "lightning": 0.20, "violet": 0.15, "fire": 0.45, "ice": -0.25
}
const COOLDOWNS := {"smoke": 3, "meteors": 3, "summon": 4}
const AI_WEIGHTS := {"physical": 105, "smoke": 85, "meteors": 72, "summon": 118}
const PHASE_THRESHOLD := 0.5
const PHASE_TWO_PHYSICAL_MULTIPLIER := 1.15
const PHASE_TWO_METEOR_BONUS := 5
const REACTIONS_PER_ROUND := 2
const HERO_TURNS_PER_REACTION := 2
const REACTION_DAMAGE := 22
const REACTION_PHASE_TWO_DAMAGE := 28
const MAX_MINIONS := 3
const MINIONS_PER_SUMMON := 2
const SMOKE_RADIUS := 3.0
const SMOKE_ROUNDS := 2
const AURA_DAMAGE := 16
const AURA_PHASE_TWO_DAMAGE := 20
const METEOR_DAMAGE := 40
const MINION_INITIATIVE := 17

const SHIELD_DURATION := 2
const SHIELD_DAMAGE_MULTIPLIER := 0.6
const SHIELD_RETALIATION := 6
const SHIELD_COOLDOWN := 3
const AURA_DURATION := 3
const FIRE_DAMAGE := 8
const FIRE_ROUNDS := 2
const EMERGENCY_DISTANCE := 2
const GUARD_MANA := 8
