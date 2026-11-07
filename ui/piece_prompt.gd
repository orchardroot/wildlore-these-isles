class_name PiecePrompt
extends RefCounted
## STUB of session P's contract (wave 48): called once by every minigame screen when a game finishes. The stub records
## the score and shows a toast; P's version also offers the unlocked piece to the lead creature.

static func after_game(host: Node, game_id: String, score: float) -> void:
	var res := PartyPieces.record(Game.data, game_id, score)
	var rosette := int(res.rosette)
	if rosette <= 0 or host == null or not host.is_inside_tree():
		return
	var names := ["", "Bronze", "Silver", "Gold"]
	var e: Dictionary = PartyPieces.entries().get(game_id, {})
	var msg := "%s rosette: %s." % [names[clampi(rosette, 0, 3)], str(e.get("name", game_id))]
	if bool(res.unlocked):
		msg += " Your lead has picked up a party piece."
	var l := Label.new()
	l.text = msg
	l.add_theme_font_size_override("font_size", 26)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position.y = 70
	host.add_child(l)
	await host.get_tree().create_timer(2.0).timeout
	l.queue_free()
