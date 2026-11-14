class_name TypeChart
extends RefCounted
## Type effectiveness lookup built from data/types.json.

const DEFAULT_PATH := "res://data/types.json"

var types: Array = []
var _chart: Dictionary = {}  # attacker -> {"se": [...], "nve": [...], "none": [...]}

static func load_default() -> TypeChart:
	var d = JsonUtil.read(DEFAULT_PATH)
	return from_dict(d if d is Dictionary else {})

static func from_dict(d: Dictionary) -> TypeChart:
	var tc := TypeChart.new()
	tc.types = d.get("types", [])
	tc._chart = d.get("chart", {})
	return tc

func multiplier(attacker: String, defender: String) -> float:
	var row: Dictionary = _chart.get(attacker, {})
	if defender in row.get("none", []):
		return 0.0
	if defender in row.get("se", []):
		return 2.0
	if defender in row.get("nve", []):
		return 0.5
	return 1.0

func effectiveness(attacker: String, defender_types: Array) -> float:
	var m := 1.0
	for t in defender_types:
		m *= multiplier(attacker, t)
	return m

## What hits a creature of these types, as [{"type", "mult"}] biggest first (types in chart order within a tie).
## weak_to: mult above 1 (2 or 4); resists: above 0 and below 1 (1/2 or 1/4); immune: 0.
func weak_to(defender_types: Array) -> Array:
	return _against(defender_types, func(m: float) -> bool: return m > 1.0)

func resists(defender_types: Array) -> Array:
	return _against(defender_types, func(m: float) -> bool: return m > 0.0 and m < 1.0)

func immune(defender_types: Array) -> Array:
	return _against(defender_types, func(m: float) -> bool: return m == 0.0)

func _against(defender_types: Array, keep: Callable) -> Array:
	var out := []
	for atk in types:
		var m := effectiveness(str(atk), defender_types)
		if keep.call(m):
			out.append({"type": atk, "mult": m})
	out.sort_custom(func(a, b): return a.mult > b.mult or (a.mult == b.mult and types.find(a.type) < types.find(b.type)))
	return out

## What a move of this type is strong against (double damage), weak against (half) and useless against (none), as
## type ids in chart order. Used on move descriptions.
func strong_against(attacker: String) -> Array:
	return _row(attacker, "se")

func weak_against(attacker: String) -> Array:
	return _row(attacker, "nve")

func no_effect_on(attacker: String) -> Array:
	return _row(attacker, "none")

func _row(attacker: String, key: String) -> Array:
	var row: Dictionary = _chart.get(attacker, {})
	return types.filter(func(t): return t in row.get(key, []))

## "x2", "x4", "x1/2", "x1/4" or "No effect" for a multiplier ("x1" for a plain hit).
static func mult_words(m: float) -> String:
	if m == 0.0:
		return "No effect"
	if m >= 4.0:
		return "x4"
	if m > 1.0:
		return "x2"
	if m <= 0.25:
		return "x1/4"
	if m < 1.0:
		return "x1/2"
	return "x1"

func validate() -> Array:
	var errors := []
	var weak := {}
	for atk in _chart:
		if atk not in types:
			errors.append("chart row for unknown type '%s'" % atk)
		var row: Dictionary = _chart[atk]
		for key in ["se", "nve", "none"]:
			for t in row.get(key, []):
				if t not in types:
					errors.append("%s.%s lists unknown type '%s'" % [atk, key, t])
		for t in row.get("se", []):
			weak[t] = true
		if row.get("se", []).is_empty() and atk != "kin":
			errors.append("type '%s' has no super-effective target" % atk)
	for t in types:
		if not weak.has(t):
			errors.append("type '%s' has no weakness" % t)
	return errors
