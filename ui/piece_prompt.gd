class_name PiecePrompt
extends RefCounted
## STUB (wave 48 G4) of session P's contract: awaitable, does nothing. The integrator drops P's real file over this.

static func after_game(_host: Node, _game_id: String, _score: float) -> void:
	await Engine.get_main_loop().process_frame
