class_name KeeperIntel
extends RefCounted
## Know your Keeper (wave 47): what each of the ten Stone holders leans on, what bites them, and how much of it the
## player has found out. Types and "beats" come straight from the team and the TypeChart; gossip from residents of the
## Keeper's town (data/keeper_gossip.json) records a flag and reveals one team member in the Almanac's Keepers page.
## Pure: no autoloads. Flags: kg_<keeper>_<i> per line heard.

const GOSSIP_PATH := "res://data/keeper_gossip.json"
## id -> [name, town (visited_<town>), hall zone, badge flag]
const KEEPERS := {
	"maud": ["Maud", "buxton", "buxton_spa", "badge_brook"], "ray": ["Ray", "liverpool", "liverpool_club", "badge_urban"],
	"eluned": ["Eluned", "llanberis", "llanberis_quarry", "badge_stone"], "rhys": ["Rhys", "cardiff", "cardiff_arena", "badge_storm"],
	"morwen": ["Morwen", "glastonbury", "glastonbury_tor", "badge_fae"], "declan": ["Declan", "dublin", "dublin_hall", "badge_kin"],
	"nuala": ["Nuala", "galway", "galway_docks", "badge_tide"], "ruairi": ["Ruairi", "belfast", "belfast_yard", "badge_iron"],
	"isla": ["Isla", "inverness", "inverness_rink", "badge_frost"], "hester": ["Hester", "york", "york_minster_crypt", "badge_spirit"],
}
## A sign in the hall that carries the Keeper's line: the sign whose text holds this (default "Keeper").
const SIGN_MARK := {"glastonbury_tor": "THE ORCHARD", "york_minster_crypt": "THE UNDERCROFT"}

static var _dex: Dex
static var _gossip: Dictionary = {}
static var _index: Dictionary = {}

static func ids() -> Array:
	return KEEPERS.keys()

## "keeper_morwen" or "keeper_morwen_rematch" -> "morwen"; "" when it is not one of the ten.
static func id_of_trainer(trainer_id: String) -> String:
	if not trainer_id.begins_with("keeper_"):
		return ""
	var k := trainer_id.substr(7).replace("_rematch", "")
	return k if KEEPERS.has(k) else ""

static func name_of(keeper: String) -> String:
	return "Keeper " + str(KEEPERS.get(keeper, ["?"])[0])

static func town(keeper: String) -> String:
	return str(KEEPERS.get(keeper, ["", ""])[1])

static func trainer_id(keeper: String) -> String:
	return "keeper_" + keeper

## The team's species ids, in battle order.
static func team(keeper: String) -> Array:
	var t: Dictionary = StoryData.trainer(trainer_id(keeper))
	return t.get("party", []).map(func(p): return str(p.get("species", "")))

static func _species_types(sp: String) -> Array:
	if _dex == null:
		_dex = Dex.load_default()
	return _dex.get_species(sp).get("types", [])

## The types the team leans on, most common first (at most 2).
static func types(keeper: String) -> Array:
	var count := {}
	var order: Array = []
	for sp in team(keeper):
		for ty in _species_types(str(sp)):
			if not count.has(ty):
				order.append(ty)
			count[ty] = int(count.get(ty, 0)) + 1
	order.sort_custom(func(a, b): return int(count[a]) > int(count[b]))
	return order.slice(0, 2)

## Types that are super-effective against at least half the team, best first (at most 3, and always at least one).
static func beats(keeper: String, chart: TypeChart) -> Array:
	var tm := team(keeper)
	var hits := {}
	for atk in chart.types:
		var n := 0
		for sp in tm:
			if chart.effectiveness(str(atk), _species_types(str(sp))) > 1.0:
				n += 1
		if n > 0:
			hits[atk] = n
	var out: Array = hits.keys()
	out.sort_custom(func(a, b): return int(hits[a]) > int(hits[b]))
	var need := ceili(tm.size() / 2.0)
	var good := out.filter(func(t): return int(hits[t]) >= need)
	return (good if not good.is_empty() else out).slice(0, 3)

static func join_types(ts: Array) -> String:
	var n := ts.map(func(t): return str(t).capitalize())
	if n.size() <= 1:
		return "".join(n)
	return ", ".join(n.slice(0, n.size() - 1)) + " and " + str(n[n.size() - 1])

## True if any of these move types is one that bites (`move_types` are the types of the party's moves).
static func has_bite(move_types: Array, bites: Array) -> bool:
	for t in move_types:
		if t in bites:
			return true
	return false

# --- gossip ---------------------------------------------------------------------------------------------------

static func gossip(keeper: String) -> Array:
	if _gossip.is_empty():
		var d = JsonUtil.read(GOSSIP_PATH)
		_gossip = d if d is Dictionary else {}
	return _gossip.get(keeper, [])

static func flag_key(keeper: String, i: int) -> String:
	return "kg_%s_%d" % [keeper, i]

static func heard(data: GameStateData, keeper: String) -> int:
	var n := 0
	for i in gossip(keeper).size():
		if data.flag(flag_key(keeper, i)) == true:
			n += 1
	return n

## The lines gathered so far, in the order they were written.
static func hints(data: GameStateData, keeper: String) -> Array:
	var out := []
	var g := gossip(keeper)
	for i in g.size():
		if data.flag(flag_key(keeper, i)) == true:
			out.append(str(g[i].get("line", "")))
	return out

static func beaten(data: GameStateData, keeper: String) -> bool:
	return data.flag("trainer_" + trainer_id(keeper)) == true or data.flag(str(KEEPERS[keeper][3])) == true

## Species revealed so far: the whole team once beaten, else one member per line of gossip heard.
static func team_known(data: GameStateData, keeper: String) -> Array:
	var tm := team(keeper)
	if beaten(data, keeper):
		return tm
	return tm.slice(0, mini(heard(data, keeper), tm.size()))

## On the Almanac page once met (beaten), the town visited, or any gossip heard.
static func known(data: GameStateData, keeper: String) -> bool:
	return beaten(data, keeper) or data.flag("visited_" + town(keeper)) == true or heard(data, keeper) > 0

static func known_ids(data: GameStateData) -> Array:
	return ids().filter(func(k): return known(data, str(k)))

# --- the hook -------------------------------------------------------------------------------------------------

static func _lookup() -> Dictionary:
	if _index.is_empty():
		for k in ids():
			var g := gossip(str(k))
			for i in g.size():
				_index["%s|%s" % [g[i].get("zone", ""), g[i].get("npc", "")]] = [str(k), i]
		_index["_"] = true
	return _index

## ScriptHooks line: the resident adds a word about their Keeper once, after what they would have said.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	var hit = _lookup().get(zone_id + "|" + npc_id)
	if hit == null:
		return commands
	var k := str(hit[0])
	var i := int(hit[1])
	if data.flag(flag_key(k, i)) == true:
		return commands
	return commands + [{"do": "say", "who": "", "text": str(gossip(k)[i].get("line", ""))}, {"do": "set", "flag": flag_key(k, i)}]

# --- the hall door --------------------------------------------------------------------------------------------

## "Keeper Maud, Brook and Bog. Storm and Frost moves bite." when `sign_text` is the sign that names her; [] otherwise.
static func door_line(zone_id: String, data: GameStateData, sign_text := "", chart: TypeChart = null) -> Array:
	for k in ids():
		if str(KEEPERS[k][2]) != zone_id:
			continue
		if not sign_text.contains(str(SIGN_MARK.get(zone_id, "Keeper"))):
			return []
		if chart == null:
			chart = TypeChart.load_default()
		return ["%s, %s. %s moves bite." % [name_of(str(k)), join_types(types(str(k))), join_types(beats(str(k), chart))]]
	return []
