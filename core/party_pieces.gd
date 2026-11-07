class_name PartyPieces
extends RefCounted
## Party pieces: a move taught by doing well at a minigame. Every res://data/party_pieces/*.json is a dict
## {game_id: entry} merged together; GameStateData.pieces holds {game_id: {best, plays, rosette}}.
## Rosettes: 1 bronze = finished, 2 silver = reached `good` (unlocks the piece), 3 gold = reached `master`.
## (STUB of the session P contract: the integrator replaces this with P's version.) Pure, no autoloads.

const DIR := "res://data/party_pieces"
static var _entries: Dictionary = {}

static func entries() -> Dictionary:
	if _entries.is_empty():
		for path in JsonUtil.list_json(DIR):
			var d = JsonUtil.read(path)
			if d is Dictionary:
				_entries.merge(d, true)
	return _entries

static func entry(game_id: String) -> Dictionary:
	return entries().get(game_id, {})

static func _reached(e: Dictionary, score: float, key: String) -> bool:
	return score <= float(e.get(key, 0)) if bool(e.get("lower_better", false)) else score >= float(e.get(key, 0))

static func _better(e: Dictionary, a: float, b: float) -> bool:
	return a < b if bool(e.get("lower_better", false)) else a > b

## Records a finished game: {rosette: new rosette (0 if unchanged), unlocked: this play unlocked the piece}.
static func record(data: GameStateData, game_id: String, score: float) -> Dictionary:
	var e := entry(game_id)
	if e.is_empty():
		return {"rosette": 0, "unlocked": false}
	var st: Dictionary = data.pieces.get(game_id, {"best": score, "plays": 0, "rosette": 0})
	var old := int(st.get("rosette", 0))
	var now := 1
	if _reached(e, score, "good"):
		now = 2
	if _reached(e, score, "master"):
		now = 3
	st["plays"] = int(st.get("plays", 0)) + 1
	if int(st.plays) == 1 or _better(e, score, float(st.get("best", score))):
		st["best"] = score
	st["rosette"] = maxi(old, now)
	data.pieces[game_id] = st
	if now == 3 and old < 3:
		TrainerStats.add(data, "masters_beaten")
	return {"rosette": int(st.rosette) if int(st.rosette) > old else 0, "unlocked": old < 2 and int(st.rosette) >= 2}

static func unlocked(data: GameStateData, game_id: String) -> bool:
	return int(data.pieces.get(game_id, {}).get("rosette", 0)) >= 2

static func can_learn(c: Creature, game_id: String, move_db: MoveDB) -> bool:
	var e := entry(game_id)
	if e.is_empty() or c.has_move(str(e.move)) or move_db.get_move(str(e.move)).is_empty():
		return false
	var types: Array = e.get("types", [])
	if types.is_empty():
		return true
	for t in c.types():
		if types.has(t):
			return true
	return false

static func party_knows(data: GameStateData, move_id: String) -> bool:
	for c in data.party:
		if c.has_move(move_id):
			return true
	return false

static func problems(move_db: MoveDB) -> Array:
	var out := []
	for id in entries():
		var e: Dictionary = entries()[id]
		var m := move_db.get_move(str(e.get("move", "")))
		if m.is_empty():
			out.append("party piece %s: move '%s' does not exist" % [id, e.get("move", "")])
		elif str(m.get("piece", "")) != id:
			out.append("party piece %s: move '%s' has piece '%s'" % [id, e.move, m.get("piece", "")])
		var good := float(e.get("good", 0))
		var master := float(e.get("master", 0))
		if (master > good) if bool(e.get("lower_better", false)) else (master < good):
			out.append("party piece %s: good and master are the wrong way round" % id)
	return out
