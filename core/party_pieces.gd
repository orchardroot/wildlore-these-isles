class_name PartyPieces
extends RefCounted
## STUB (wave 48 G4) of session P's contract: same signatures, inert behaviour. The integrator drops P's real file
## over this one. See docs/briefs/wave48.md.

static func entries() -> Dictionary:
	return {}

static func record(_data, _game_id: String, _score: float) -> Dictionary:
	return {"rosette": 0, "unlocked": false}

static func unlocked(_data, _game_id: String) -> bool:
	return false

static func can_learn(_c, _game_id: String, _move_db) -> bool:
	return false

static func party_knows(_data, _move_id: String) -> bool:
	return false

static func problems(_move_db) -> Array:
	return []
