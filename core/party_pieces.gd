class_name PartyPieces
extends RefCounted
## Party pieces (wave 48): the TM/HM replacement. Every minigame teaches one move nobody can buy. Play well (reach the
## entry's "good" score) and your lead creature picks it up; beat the local champion ("master") for a gold rosette.
## Some pieces are also field pieces (entry "field": a verb for the optional nooks out in the world).
## Data: every data/party_pieces/*.json is {"<game_id>": entry}; state: GameStateData.pieces
## ({game_id: {"best", "plays", "rosette"}}). Pure logic, no autoloads.

const DIR := "res://data/party_pieces"
const GOLD_PRIZE := 150   # pounds, once per game

static var _cache: Dictionary = {}

## Every entry, merged from all files, keyed by game id.
static func entries() -> Dictionary:
	if _cache.is_empty():
		for path in JsonUtil.list_json(DIR):
			var d = JsonUtil.read(path)
			if d is Dictionary:
				for k in d:
					if d[k] is Dictionary:
						_cache[str(k)] = d[k]
	return _cache

static func entry(game_id: String) -> Dictionary:
	return entries().get(game_id, {})

static func ids() -> Array:
	var out := entries().keys()
	out.sort()
	return out

static func state(data: GameStateData, game_id: String) -> Dictionary:
	var s = data.pieces.get(game_id)
	return s if s is Dictionary else {"best": 0.0, "plays": 0, "rosette": 0}

static func rosette(data: GameStateData, game_id: String) -> int:
	return int(state(data, game_id).get("rosette", 0))

static func _reached(e: Dictionary, score: float, target: float) -> bool:
	return score <= target if bool(e.get("lower_better", false)) else score >= target

static func _better(e: Dictionary, score: float, old: float) -> bool:
	return score < old if bool(e.get("lower_better", false)) else score > old

## A save's pieces block, cleaned: only well-formed entries, rosette 0..3.
static func sanitise(raw) -> Dictionary:
	var out := {}
	if raw is Dictionary:
		for k in raw:
			var v = raw[k]
			if v is Dictionary:
				out[str(k)] = {"best": float(v.get("best", 0.0)), "plays": maxi(0, int(v.get("plays", 0))), "rosette": clampi(int(v.get("rosette", 0)), 0, 3)}
	return out

## A game finished with this score. Returns {"rosette": new rosette or 0 if unchanged, "unlocked": bool, "prize": pounds}.
static func record(data: GameStateData, game_id: String, score: float) -> Dictionary:
	var out := {"rosette": 0, "unlocked": false, "prize": 0}
	var e := entry(game_id)
	if e.is_empty():
		return out
	var s := state(data, game_id).duplicate()
	var plays := int(s.get("plays", 0))
	if plays == 0 or _better(e, score, float(s.get("best", 0.0))):
		s["best"] = score
	s["plays"] = plays + 1
	var old := int(s.get("rosette", 0))
	var now := 1
	if _reached(e, score, float(e.get("good", 0))):
		now = 2
	if _reached(e, score, float(e.get("master", 0))):
		now = 3
	now = maxi(now, old)
	s["rosette"] = now
	data.pieces[game_id] = s
	if now > old:
		out["rosette"] = now
		out["unlocked"] = old < 2 and now >= 2
		if now == 3:
			TrainerStats.add(data, "masters_beaten")
			out["prize"] = GOLD_PRIZE
			data.money += GOLD_PRIZE
			TrainerStats.earned(data, GOLD_PRIZE)
	return out

static func unlocked(data: GameStateData, game_id: String) -> bool:
	return rosette(data, game_id) >= 2

static func move_of(game_id: String) -> String:
	return str(entry(game_id).get("move", ""))

## Types empty (anyone) or overlapping the creature's; not already known.
static func can_learn(c: Creature, game_id: String, move_db: MoveDB) -> bool:
	var e := entry(game_id)
	if c == null or e.is_empty() or not move_db.has(str(e.move)) or c.has_move(str(e.move)):
		return false
	var types: Array = e.get("types", [])
	if types.is_empty():
		return true
	for t in c.types():
		if t in types:
			return true
	return false

## Does anyone in the party already know this move?
static func party_knows(data: GameStateData, move_id: String) -> bool:
	for c in data.party:
		if c.has_move(move_id):
			return true
	return false

## Unlocked pieces whose field verb is `verb`, known by someone in the party (the field spots ask this).
static func field_known(data: GameStateData, verb: String) -> bool:
	for id in entries():
		var e: Dictionary = entries()[id]
		if str(e.get("field", "")) == verb and unlocked(data, id) and party_knows(data, str(e.move)):
			return true
	return false

## The piece for a field verb, or "".
static func game_for_field(verb: String) -> String:
	for id in ids():
		if str(entries()[id].get("field", "")) == verb:
			return id
	return ""

## Validator: every entry's move exists with the matching "piece" key, zones exist, scores ordered right.
static func problems(move_db: MoveDB, zone_ok := Callable()) -> Array:
	var out := []
	for id in ids():
		var e: Dictionary = entries()[id]
		var mid := str(e.get("move", ""))
		if not move_db.has(mid):
			out.append("party piece %s: move '%s' does not exist" % [id, mid])
		elif str(move_db.get_move(mid).get("piece", "")) != id:
			out.append("party piece %s: move '%s' lacks \"piece\": \"%s\"" % [id, mid, id])
		var zok: bool = zone_ok.call(str(e.get("zone", ""))) if zone_ok.is_valid() else ZoneData.load_id(str(e.get("zone", ""))) != null
		if not zok:
			out.append("party piece %s: zone '%s' does not exist" % [id, e.get("zone", "")])
		var good := float(e.get("good", 0))
		var master := float(e.get("master", 0))
		var lower := bool(e.get("lower_better", false))
		if (lower and master >= good) or (not lower and master <= good):
			out.append("party piece %s: master must be harder than good" % id)
		for k in ["name", "where", "unit", "master_name"]:
			if str(e.get(k, "")) == "":
				out.append("party piece %s: missing %s" % [id, k])
		if "—" in JSON.stringify(e):
			out.append("party piece %s: em-dash in text" % id)
	for m in move_db.ids():
		var pc := str(move_db.get_move(m).get("piece", ""))
		if pc != "" and not entries().has(pc):
			out.append("move %s: piece '%s' has no entry" % [m, pc])
	return out
