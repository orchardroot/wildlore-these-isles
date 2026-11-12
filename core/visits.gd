class_name Visits
extends RefCounted
## Return visits (wave 53): a home resident who notices you've been before. data/visits/*.json holds, per resident
## ("<zone>|<npc>"), optional extra lines: `again` (any visit after the first), `morning` / `evening` (by the clock),
## `season` {spring..winter: [lines]} and `weather` {rain|fog|gale|frost|sunshine: [lines]}. The first talk sets
## talked_<zone>_<npc> (absent = first visit, so an old save behaves exactly as before); after that the hook appends
## ONE extra line to the talk, chosen from whichever kinds apply right now. A resident with no entry is untouched.
## Pure: no autoload names (the validator loads it). Hook it from ScriptHooks.wrap.

const DIR := "res://data/visits"
const FLAG_PREFIX := "talked_"
const KINDS := ["again", "morning", "evening", "season", "weather"]
## Weather keys follow the dialogue `when` conditions (story/commands.gd WEATHER_CONDS) so there is one idea of "rain".
const WEATHER_KEYS := {"rain": ["drizzle", "downpour"], "fog": ["fog"], "gale": ["gale"], "frost": ["frost"], "sunshine": ["sunshine"]}

static var _all: Dictionary = {}
static var _loaded := false

static func reset() -> void:
	_all = {}
	_loaded = false

## "<zone>|<npc>" -> entry.
static func all() -> Dictionary:
	if not _loaded:
		_loaded = true
		var d := DirAccess.open(DIR)
		if d:
			var names := Array(d.get_files())
			names.sort()
			for f in names:
				if f.ends_with(".json"):
					var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/" + f))
					if j is Dictionary:
						_all.merge(j, true)
	return _all

static func key(zone_id: String, npc_id: String) -> String:
	return zone_id + "|" + npc_id

static func flag_key(zone_id: String, npc_id: String) -> String:
	return FLAG_PREFIX + zone_id + "_" + npc_id

static func _lines(v: Variant) -> Array:
	return v if v is Array else []

## "morning" before noon, "evening" from six in the evening until the small hours, otherwise "".
static func time_kind(minutes: int) -> String:
	var m := GameClock.wrap(minutes)
	if m >= 5 * 60 and m < 12 * 60:
		return "morning"
	if m >= 18 * 60 or m < 5 * 60:
		return "evening"
	return ""

## "rain", "fog", ... for a saved outdoor weather id, or "".
static func weather_key(weather: String) -> String:
	for k in WEATHER_KEYS:
		if weather in WEATHER_KEYS[k]:
			return k
	return ""

## The lines that fit right now, as a list of lists (one per kind that applies). `again` is always among them.
static func pools(entry: Dictionary, minutes: int, season: String, weather: String) -> Array:
	var out: Array = []
	var w := weather_key(weather)
	var wl := _lines(entry.get("weather", {}).get(w, [])) if w != "" and entry.get("weather") is Dictionary else []
	if not wl.is_empty():
		out.append(wl)
	var tl := _lines(entry.get(time_kind(minutes), [])) if time_kind(minutes) != "" else []
	if not tl.is_empty():
		out.append(tl)
	var sl := _lines(entry.get("season", {}).get(season, [])) if entry.get("season") is Dictionary else []
	if not sl.is_empty():
		out.append(sl)
	var al := _lines(entry.get("again", []))
	if not al.is_empty():
		out.append(al)
	return out

## One line from the pools: `salt` picks the kind, then the line (so the same moment gives the same line).
static func pick(pool_list: Array, salt: int) -> String:
	if pool_list.is_empty():
		return ""
	var lines: Array = pool_list[posmod(salt, pool_list.size())]
	return str(lines[posmod(salt / maxi(pool_list.size(), 1), lines.size())])

static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	var entry: Variant = all().get(key(zone_id, npc_id))
	if not entry is Dictionary:
		return commands
	var f := flag_key(zone_id, npc_id)
	if data.flag(f) != true:
		return commands + [{"do": "set", "flag": f}]  # the first talk is today's talk, unchanged
	var minutes := Timezones.local_minutes(data, data.tz_zone)
	var line := pick(pools(entry, minutes, Calendar.season_today(), data.weather), salt(zone_id, npc_id, data, minutes))
	if line == "":
		return commands
	return commands + [{"do": "say", "who": str(entry.get("who", "")), "text": line}]

## Stable within a half hour of a day, different on another day or for another resident.
static func salt(zone_id: String, npc_id: String, data: GameStateData, minutes: int) -> int:
	return absi(hash(zone_id + npc_id)) + data.day_count * 7 + minutes / 30

## Problems in data/visits for the validator: bad shape, unknown zone or npc, a `who` that isn't the NPC's name,
## and (with `zones`) a home resident with no `again` line.
static func check(zones: Dictionary) -> Array:
	var errors: Array = []
	for k in all():
		var parts := str(k).split("|")
		var e: Variant = all()[k]
		if parts.size() != 2 or not zones.has(parts[0]):
			errors.append("visits: %s is not <zone>|<npc> in a real zone" % k)
			continue
		var npc: Variant = null
		for n in zones[parts[0]].npcs:
			if str(n.get("id", "")) == parts[1]:
				npc = n
		if npc == null:
			errors.append("visits: %s has no such npc" % k)
			continue
		if not e is Dictionary:
			errors.append("visits: %s is not an object" % k)
			continue
		for c in e:
			if c != "who" and c not in KINDS:
				errors.append("visits: %s has unknown key %s" % [k, c])
		var nm := str(npc.get("name", ""))
		if nm != "" and str(e.get("who", "")) != nm:
			errors.append("visits: %s who should be %s" % [k, nm])
		for kind in KINDS:
			if not e.has(kind):
				continue
			if kind == "season" or kind == "weather":
				var keys: Array = ["spring", "summer", "autumn", "winter"] if kind == "season" else WEATHER_KEYS.keys()
				if not e[kind] is Dictionary:
					errors.append("visits: %s %s must be an object" % [k, kind])
					continue
				for sub in e[kind]:
					if sub not in keys:
						errors.append("visits: %s %s has unknown key %s" % [k, kind, sub])
					elif not _good_list(e[kind][sub]):
						errors.append("visits: %s %s.%s must be a non-empty list of strings" % [k, kind, sub])
			elif not _good_list(e[kind]):
				errors.append("visits: %s %s must be a non-empty list of strings" % [k, kind])
	return errors

static func _good_list(v: Variant) -> bool:
	if not v is Array or v.is_empty():
		return false
	for s in v:
		if not s is String or str(s).strip_edges() == "" or "—" in str(s):
			return false
	return true

## Home residents (non-teacher, non-case npcs of a home zone) with no entry or no `again` line.
static func missing_again(zones: Dictionary) -> Array:
	var out: Array = []
	for zid in zones:
		var z := str(zid)
		if not (z.contains("home") or z.contains("house") or z.contains("cottage")):
			continue
		for n in zones[zid].npcs:
			var s := str(n.get("script", ""))
			if s == "" or s.begins_with("teach_") or s.begins_with("case_"):
				continue
			var e: Variant = all().get(key(z, str(n.get("id", ""))))
			if not e is Dictionary or _lines(e.get("again", [])).is_empty():
				out.append(key(z, str(n.get("id", ""))))
	return out
