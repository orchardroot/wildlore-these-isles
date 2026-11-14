class_name Encounters
extends RefCounted
## Wild encounters: a 1 in 10 chance per step in tall grass (1 in 20 wading), then a weighted pick among the zone's entries
## that suit the time of day, the weather and the season. A short grace period follows each battle.

const STEP_CHANCE := 10.0
const WATER_STEP_CHANCE := 5.0   # wading is a gentler way to meet things
const GRACE_STEPS := 5
const FEATURED_MULT := 3.0  # Today's Walk: the featured species is three times as likely in its zone

var _grace := 0

## `featured_species`: Today's Walk species for this zone ("" for none, see TodaysWalk.featured_in).
## `flags`: the save's flags, for entries gated on one (see candidates).
static func roll(zone: ZoneData, tile: String, phase: String, weather: String, rng: Rng, featured_species := "", flags := {}) -> Dictionary:
	var kind: String = {"tall_grass": "grass", "deep_water": "water", "water": "water", "sea": "water", "bog": "grass"}.get(tile, "")
	if kind == "":
		return {}
	if not rng.chance(step_chance(tile) * Meals.lure_mult(flags)):
		return {}
	var list := featured(candidates(zone, kind, phase, weather, flags), featured_species)
	if list.is_empty():
		return {}
	var e := pick_entry(list, rng.roll())
	var lo := int(e.get("min", 2))
	var hi := maxi(lo, int(e.get("max", lo)))
	var lv := rng.roll_int(lo, hi)
	if zone.scaled_floor >= 0:  # off the main line: lifted to the story's par (the overworld evolves the species to suit)
		return {"species": str(e.species), "level": ParLevel.lift(lv, flags, zone.scaled_floor), "scaled": true}
	return {"species": str(e.species), "level": lv}

## Percent chance per step on this tile (0 where nothing lives).
static func step_chance(tile: String) -> float:
	match tile:
		"tall_grass", "bog":
			return STEP_CHANCE
		"deep_water", "water", "sea":
			return WATER_STEP_CHANCE  # afloat in the coracle: the player is only ever on `~` or `$` in one
	return 0.0

## A catch is worth banking straight away (the battle is over and nothing is half-done).
static func autosave_after(result: Dictionary) -> bool:
	return str(result.get("result", "")) == "caught"

## An entry with "requires_flag" only turns up once that flag is at least "flag_at_least" (default 1), e.g. a
## creature that comes back to a rewilded site (Rewild); with no flags given, gated entries never do.
## An entry with a "season" list only turns up in those seasons (the real-date season, see Calendar; `season`
## "" means today's).
static func candidates(zone: ZoneData, kind: String, phase: String, weather: String, flags := {}, season := "") -> Array:
	var out := []
	var now := season if season != "" else Calendar.season_today()
	for e in zone.encounters.get(kind, []):
		var seasons: Array = e.get("season", [])
		if not seasons.is_empty() and now not in seasons:
			continue
		if e.has("requires_flag"):
			var v: Variant = flags.get(str(e.requires_flag))
			if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) < float(e.get("flag_at_least", 1)):
				continue
		var times: Array = e.get("time", [])
		var weathers: Array = e.get("weather", [])
		if (times.is_empty() or phase in times) and (weathers.is_empty() or weather in weathers):
			out.append(e)
	out.append_array(Festivals.extra_encounters(zone.id, kind, zone.encounters.get(kind, [])))  # a festival creature, while it is on
	return WeatherWild.shift(out, weather, WeatherWild.dex_types, float(flags.get(Trades.SKY_FLAG, 0.0)) if flags.get(Trades.SKY_FLAG) is float else 0.0)  # the sky favours some types (3.1)

## The list with `species`' weight tripled (copies; the zone's own table is untouched). "" or absent: unchanged.
static func featured(list: Array, species: String) -> Array:
	if species == "" or not list.any(func(e): return str(e.get("species", "")) == species):
		return list
	var out := []
	for e in list:
		if str(e.get("species", "")) == species:
			var b: Dictionary = e.duplicate()
			b["weight"] = float(e.get("weight", 1)) * FEATURED_MULT
			out.append(b)
		else:
			out.append(e)
	return out

## `u` in 0..1 chooses along the cumulative weights.
static func pick_entry(list: Array, u: float) -> Dictionary:
	var total := 0.0
	for e in list:
		total += float(e.get("weight", 1))
	var r := clampf(u, 0.0, 0.9999) * total
	for e in list:
		r -= float(e.get("weight", 1))
		if r < 0.0:
			return e
	return list.back()

func after_battle() -> void:
	_grace = GRACE_STEPS

func stepped() -> void:
	_grace = maxi(0, _grace - 1)

func in_grace() -> bool:
	return _grace > 0
