class_name PartyPieces
extends RefCounted
## STUB (session G5) of the party pieces contract from docs/briefs/wave48.md; session P owns the real one and the
## integrator drops this file. Same signatures. State lives in GameStateData.pieces when P's field exists, else in a
## flag so the stub never touches the save format.

const DIR := "res://data/party_pieces"
const FLAG := "pieces_stub"

static var _cache: Dictionary = {}

static func entries() -> Dictionary:
	if _cache.is_empty():
		var d := DirAccess.open(DIR)
		if d != null:
			var files := Array(d.get_files())
			files.sort()
			for f in files:
				if str(f).ends_with(".json"):
					var j = JsonUtil.read(DIR + "/" + str(f))
					if j is Dictionary:
						_cache.merge(j, true)
	return _cache

static func _state(data) -> Dictionary:
	if "pieces" in data:
		return data.pieces
	var f = data.flag(FLAG)
	if not (f is Dictionary):
		f = {}
		data.set_flag(FLAG, f)
	return f

static func state_for(data, game_id: String) -> Dictionary:
	return _state(data).get(game_id, {"best": 0.0, "plays": 0, "rosette": 0})

static func record(data, game_id: String, score: float) -> Dictionary:
	var e: Dictionary = entries().get(game_id, {})
	var st := _state(data)
	var cur: Dictionary = st.get(game_id, {"best": 0.0, "plays": 0, "rosette": 0})
	var lower := bool(e.get("lower_better", false))
	var old_r := int(cur.rosette)
	cur.plays = int(cur.plays) + 1
	if int(cur.plays) == 1 or (score < float(cur.best) if lower else score > float(cur.best)):
		cur.best = score
	var r := 1
	if not e.is_empty():
		var good := float(e.get("good", 0))
		var master := float(e.get("master", 0))
		if (score <= master) if lower else (score >= master):
			r = 3
		elif (score <= good) if lower else (score >= good):
			r = 2
	cur.rosette = maxi(old_r, r)
	st[game_id] = cur
	var up: bool = int(cur.rosette) > old_r
	return {"rosette": int(cur.rosette) if up else 0, "unlocked": up and old_r < 2 and int(cur.rosette) >= 2}

static func unlocked(data, game_id: String) -> bool:
	return int(state_for(data, game_id).rosette) >= 2

static func can_learn(c, game_id: String, move_db) -> bool:
	var e: Dictionary = entries().get(game_id, {})
	if e.is_empty():
		return false
	for m in c.moves:
		if str(m.get("id", m)) == str(e.move):
			return false
	var types: Array = e.get("types", [])
	if types.is_empty():
		return true
	for t in c.types():
		if str(t) in types:
			return true
	return false

static func party_knows(data, move_id: String) -> bool:
	for c in data.party:
		for m in c.moves:
			if str(m.get("id", m)) == move_id:
				return true
	return false

static func problems(_move_db) -> Array:
	return []
