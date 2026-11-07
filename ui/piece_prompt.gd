class_name PiecePrompt
extends RefCounted
## STUB (wave 48 F) of session P's contract. Every minigame screen calls after_game once when a game finishes.

static func after_game(_host: Node, game_id: String, score: float) -> void:
	PartyPieces.record(Game.data, game_id, score)
