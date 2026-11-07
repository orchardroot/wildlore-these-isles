class_name PartyPieces
extends RefCounted
## STUB (wave 48 F) of session P's contract, for the integrator to drop in favour of the real file.
## Pure: no autoloads. Party pieces: moves learnt by doing well at a minigame (see docs/briefs/wave48.md).

const DIR := "res://data/party_pieces"

static var _entries: Dictionary = {}
static var _loaded := false

static func entries() -> Dictionary:
	if not _loaded:
		_loaded = true
		var d := DirAccess.open(DIR)
		if d:
			for f in d.get_files():
				if f.ends_with(".json"):
					var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/" + f))
					if j is Dictionary:
						_entries.merge(j)
	return _entries

static func record(data: GameStateData, game_id: String, score: float) -> Dictionary:
	var e: Dictionary = entries().get(game_id, {})
	var st: Dictionary = data.pieces.get(game_id, {"best": 0.0, "plays": 0, "rosette": 0})
	var lower := bool(e.get("lower_better", false))
	var better: bool = int(st.plays) == 0 or (score < float(st.best) if lower else score > float(st.best))
	st.plays = int(st.plays) + 1
	if better:
		st.best = score
	var was := int(st.rosette)
	var now := 1
	if not e.is_empty():
		var good := float(e.get("good", 0))
		var master := float(e.get("master", 0))
		if (score <= master) if lower else (score >= master):
			now = 3
		elif (score <= good) if lower else (score >= good):
			now = 2
	now = maxi(now, was)
	st.rosette = now
	data.pieces[game_id] = st
	return {"rosette": now if now > was else 0, "unlocked": was < 2 and now >= 2}

static func unlocked(data: GameStateData, game_id: String) -> bool:
	return int(data.pieces.get(game_id, {}).get("rosette", 0)) >= 2

static func can_learn(c: Creature, game_id: String, move_db: MoveDB) -> bool:
	var e: Dictionary = entries().get(game_id, {})
	if e.is_empty() or c.has_move(str(e.move)):
		return false
	var types: Array = e.get("types", [])
	if types.is_empty():
		return true
	for t in c.types():
		if t in types:
			return true
	return false

static func party_knows(data: GameStateData, move_id: String) -> bool:
	for c in data.party:
		if c.has_move(move_id):
			return true
	return false

static func problems(_move_db: MoveDB) -> Array:
	return []
