class_name PiecePrompt
extends RefCounted
## STUB of the party pieces prompt (docs/briefs/wave48.md), written by session G3. Session P's real file replaces it.
## Every minigame screen calls `await PiecePrompt.after_game(self, "<game id>", score)` once when a game finishes.

static func after_game(host: Node, game_id: String, score: float) -> void:
	var e: Dictionary = PartyPieces.entries().get(game_id, {})
	if e.is_empty():
		return
	var r := PartyPieces.record(Game.data, game_id, score)
	var names := ["", "Bronze", "Silver", "Gold"]
	if int(r.rosette) > 0 and host.has_method("show_tip"):
		host.show_tip("%s rosette for %s." % [names[int(r.rosette)], str(e.name)])
	if not bool(r.unlocked) or Game.data.party.is_empty():
		return
	var lead: Creature = Game.data.party[0]
	var mname := str(Game.moves.get_move(str(e.move)).get("name", e.move))
	if not PartyPieces.can_learn(lead, game_id, Game.moves):
		if host.has_method("show_tip"):
			host.show_tip("%s cannot learn %s. See the Almanac." % [lead.display_name(), mname])
		return
	if lead.moves.size() < Rules.MAX_MOVES:
		Progression.relearn(lead, str(e.move), 0, Game.moves)
		Audio.sfx("heal")
		if host.has_method("show_tip"):
			host.show_tip("%s watched every go and learned %s!" % [lead.display_name(), mname])
