class_name PiecePrompt
extends RefCounted
## STUB (session G5) of the party pieces prompt from docs/briefs/wave48.md; session P owns the real one and the
## integrator drops this file. Records the score and flashes a toast; the real one also offers the move.

static func after_game(host: Node, game_id: String, score: float) -> void:
	var data = host.get("data") if host.get("data") != null else null
	if data == null:
		data = Engine.get_main_loop().root.get_node_or_null("Game")
		data = data.data if data != null else null
	if data == null:
		return
	var res := PartyPieces.record(data, game_id, score)
	if int(res.rosette) > 0:
		var names := ["", "Bronze", "Silver", "Gold"]
		var l := UIKit.label("%s rosette!" % names[int(res.rosette)], 30, UIKit.CREAM)
		l.position = Vector2(40, 90)
		host.add_child(l)
		await host.get_tree().create_timer(1.6).timeout
		l.queue_free()
