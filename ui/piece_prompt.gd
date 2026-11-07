class_name PiecePrompt
extends RefCounted
## After a minigame: records the score, shows the rosette, and offers a newly unlocked party piece to the lead
## creature. (STUB of the session P contract: the integrator replaces this with P's version.)

const ROSETTES := ["", "Bronze", "Silver", "Gold"]

static func after_game(host: Node, game_id: String, score: float) -> void:
	var e := PartyPieces.entry(game_id)
	if e.is_empty() or Game.data == null:
		return
	var r := PartyPieces.record(Game.data, game_id, score)
	if int(r.rosette) > 0:
		Audio.sfx("badge")
		await host.get_tree().process_frame
		_toast(host, "%s rosette: %s" % [ROSETTES[int(r.rosette)], str(e.get("name", game_id))])
	if not bool(r.unlocked) or Game.data.party.is_empty():
		return
	var lead: Creature = Game.data.party[0]
	var mname := str(Game.moves.get_move(str(e.move)).get("name", e.move))
	if not PartyPieces.can_learn(lead, game_id, Game.moves):
		_toast(host, "%s watched closely, but %s is not for its kind. See the Almanac." % [lead.display_name(), mname])
		return
	if lead.moves.size() < Rules.MAX_MOVES:
		Progression.relearn(lead, str(e.move), 0, Game.moves)
		Audio.sfx("heal")
		_toast(host, "%s learned %s!" % [lead.display_name(), mname])

## A banner across the top of the screen that fades after a couple of seconds.
static func _toast(host: Node, text: String) -> void:
	var l := UIKit.label(text, 28, Color("f6d98a"))
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position = Vector2(220, 70)
	l.z_index = 50
	host.add_child(l)
	var tw := host.create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
	await host.get_tree().create_timer(2.6).timeout
