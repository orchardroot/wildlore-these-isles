class_name PartyPieces
extends RefCounted
## STUB of session P's contract (wave 48): party pieces, the moves a creature picks up by watching you play a minigame.
## Rosettes: 1 bronze = finished, 2 silver = reached `good` (unlocks the piece), 3 gold = reached `master`.
## Data: every res://data/party_pieces/*.json is {"<game_id>": entry}. Pure, no autoload names.

const DIR := "res://data/party_pieces"
static var _cache: Dictionary = {}

static func entries() -> Dictionary:
	if _cache.is_empty():
		for path in JsonUtil.list_json(DIR):
			var d = JsonUtil.read(path)
			if d is Dictionary:
				_cache.merge(d, true)
	return _cache

static func _better(e: Dictionary, a: float, b: float) -> bool:
	return a <= b if bool(e.get("lower_better", false)) else a >= b

## Records a finished game. {"rosette": new rosette (0 if unchanged), "unlocked": this play unlocked the piece}.
static func record(data, game_id: String, score: float) -> Dictionary:
	var e: Dictionary = entries().get(game_id, {})
	if e.is_empty():
		return {"rosette": 0, "unlocked": false}
	var cur: Dictionary = data.pieces.get(game_id, {"best": score, "plays": 0, "rosette": 0})
	var old := int(cur.get("rosette", 0))
	var lower := bool(e.get("lower_better", false))
	var best := float(cur.get("best", score))
	best = minf(best, score) if lower and int(cur.plays) > 0 else (maxf(best, score) if int(cur.plays) > 0 else score)
	var r := 1
	if _better(e, score, float(e.get("good", 0))):
		r = 2
	if _better(e, score, float(e.get("master", 0))):
		r = 3
	r = maxi(r, old)
	data.pieces[game_id] = {"best": best, "plays": int(cur.get("plays", 0)) + 1, "rosette": r}
	return {"rosette": r if r > old else 0, "unlocked": old < 2 and r >= 2}

static func unlocked(data, game_id: String) -> bool:
	return int(data.pieces.get(game_id, {}).get("rosette", 0)) >= 2

static func can_learn(c, game_id: String, move_db) -> bool:
	var e: Dictionary = entries().get(game_id, {})
	if e.is_empty() or c.has_move(str(e.get("move", ""))):
		return false
	var types: Array = e.get("types", [])
	if types.is_empty():
		return true
	for t in c.types():
		if t in types:
			return true
	return false

static func party_knows(data, move_id: String) -> bool:
	for c in data.party:
		if c.has_move(move_id):
			return true
	return false

static func problems(move_db) -> Array:
	var out := []
	for id in entries():
		var e: Dictionary = entries()[id]
		var m: Dictionary = move_db.get_move(str(e.get("move", "")))
		if m.is_empty() or str(m.get("piece", "")) != id:
			out.append("party piece %s: move %s missing or has the wrong piece key" % [id, e.get("move", "")])
	return out
