class_name IndoorFolk
extends RefCounted
## Something lives in the house (wave 53): a home's `encounters` may carry an "indoor" table, the same entries as the
## grass table (species, min, max, weight, and optional time, weather, season). Walking about indoors has a small
## chance per step of drawing one, and the entries' own gates keep it to the hour, the weather outside (indoors the
## weather itself is always "clear", so the gate reads the sky outside) or the season it belongs to. Stateless.
## Pure logic, no autoload names.

const KIND := "indoor"
const STEP_CHANCE := 1.5   # percent per step, on top of each entry's own gates

## {species, level} for this step, or {} (nothing stirred).
static func roll(zone: ZoneData, phase: String, outside_weather: String, rng: Rng, flags := {}) -> Dictionary:
	if zone.kind != "interior" or not zone.encounters.has(KIND):
		return {}
	var list := Encounters.candidates(zone, KIND, phase, outside_weather, flags)
	if list.is_empty() or not rng.chance(STEP_CHANCE):
		return {}
	var e := Encounters.pick_entry(list, rng.roll())
	var lo := int(e.get("min", 2))
	return {"species": str(e.species), "level": rng.roll_int(lo, maxi(lo, int(e.get("max", lo))))}
