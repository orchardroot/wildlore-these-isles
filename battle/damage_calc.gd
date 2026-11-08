class_name DamageCalc
extends RefCounted
## The damage formula. Pure: same inputs and rolls, same answer.

const CRIT_CHANCE := 100.0 / 24.0
## Crit chance (percent) by stage: 1 in 24, 1 in 8, 1 in 2, always. A move's "crit" and a held charm add stages.
const CRIT_STAGES := [100.0 / 24.0, 12.5, 50.0, 100.0]
const STAB := 1.5
const CRIT_MULT := 1.5

static func crit_percent(stage: int) -> float:
	return CRIT_STAGES[clampi(stage, 0, CRIT_STAGES.size() - 1)]

## The crit stage of a move: its own "crit" (1 is "high chance") plus the user's charm.
static func crit_stage(user: Creature, move: Dictionary) -> int:
	return int(move.get("crit", 0)) + Charms.crit_stages(user)

## extra_mult: anything else that scales the hit (a spread move in a double battle hits each foe at 0.75).
static func compute(attacker: Creature, defender: Creature, move: Dictionary, chart: TypeChart, weather: String, rng: Rng, crit_chance: float = CRIT_CHANCE, extra_mult := 1.0) -> Dictionary:
	var move_type: String = move.get("type", "")
	var power: int = MoveFX.power_in(move, weather)  # some moves grow stronger in the right weather
	var eff := chart.effectiveness(move_type, defender.types())
	if eff == 0.0 or power <= 0:
		return {"damage": 0, "effectiveness": eff, "crit": false}
	var physical: bool = move.get("category") == "physical"
	var atk_stat := "atk" if physical else "lore"
	var def_stat := "def" if physical else "ward"
	var a := attacker.battle_stat(atk_stat)
	var d := defender.battle_stat(def_stat)
	var crit := rng.chance(crit_chance)
	if crit:
		# Crits ignore the attacker's drops and the defender's boosts.
		a = maxi(a, attacker.calc_stat(atk_stat))
		d = mini(d, defender.calc_stat(def_stat))
	var level_factor := floori(2.0 * attacker.level / 5.0 + 2.0)
	var base := floori(floori(level_factor * power * a / float(d)) / 50.0) + 2
	var mult := eff * Weather.damage_mod(weather, move_type) * StatusFX.incoming_mult(defender, move_type)
	mult *= Charms.incoming_mult(defender, move_type) * Charms.outgoing_mult(attacker, move_type)
	if move_type in attacker.types():
		mult *= STAB
	if crit:
		mult *= CRIT_MULT
	mult *= extra_mult
	mult *= rng.roll_range(0.85, 1.0)
	return {"damage": maxi(1, floori(base * mult)), "effectiveness": eff, "crit": crit}
