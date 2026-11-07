class_name PartyPieces
extends RefCounted
## STUB of the party pieces contract (docs/briefs/wave48.md), written by session G3 so its games compile. Session P's
## real file replaces this one; the signatures are the contract. Pure: no autoloads.

const DIR := "res://data/party_pieces"
static var _entries: Dictionary = {}

static func entries() -> Dictionary:
	if _entries.is_empty():
		var da := DirAccess.open(DIR)
		if da != null:
			for f in da.get_files():
				if f.ends_with(".json"):
					var d = JsonUtil.read(DIR + "/" + f)
					if d is Dictionary:
						_entries.merge(d, true)
	return _entries

static func _slot(data, game_id: String) -> Dictionary:
	var p: Dictionary = data.pieces
	if not p.has(game_id):
		p[game_id] = {"best": 0.0, "plays": 0, "rosette": 0}
	return p[game_id]

## Records a finished game. Returns {"rosette": new rosette or 0 if unchanged, "unlocked": bool}.
static func record(data, game_id: String, score: float) -> Dictionary:
	var e: Dictionary = entries().get(game_id, {})
	if e.is_empty():
		return {"rosette": 0, "unlocked": false}
	var s := _slot(data, game_id)
	var lower := bool(e.get("lower_better", false))
	var was := int(s.rosette)
	s.plays = int(s.plays) + 1
	if int(s.plays) == 1 or (score < float(s.best) if lower else score > float(s.best)):
		s.best = score
	var r := 1
	if (score <= float(e.good)) if lower else (score >= float(e.good)):
		r = 2
	if (score <= float(e.master)) if lower else (score >= float(e.master)):
		r = 3
	if r > was:
		s.rosette = r
		return {"rosette": r, "unlocked": was < 2 and r >= 2}
	return {"rosette": 0, "unlocked": false}

static func unlocked(data, game_id: String) -> bool:
	return int(data.pieces.get(game_id, {}).get("rosette", 0)) >= 2

static func can_learn(c: Creature, game_id: String, move_db: MoveDB) -> bool:
	var e: Dictionary = entries().get(game_id, {})
	if e.is_empty() or c.has_move(str(e.move)):
		return false
	var types: Array = e.get("types", [])
	if types.is_empty():
		return true
	for t in c.types():
		if types.has(t):
			return true
	return false

static func party_knows(data, move_id: String) -> bool:
	for c in data.party:
		if c.has_move(move_id):
			return true
	return false

static func problems(move_db: MoveDB) -> Array:
	var out := []
	for id in entries():
		var e: Dictionary = entries()[id]
		var m := move_db.get_move(str(e.get("move", "")))
		if m.is_empty() or str(m.get("piece", "")) != id:
			out.append("party piece %s: move missing or without matching piece key" % id)
	return out
