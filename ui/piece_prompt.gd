class_name PiecePrompt
extends RefCounted
## Party pieces, the player-facing half (wave 48). Every minigame screen calls `await PiecePrompt.after_game(self, id,
## score)` once when a game finishes: it records the score (see PartyPieces), shows the rosette, and if a piece just
## unlocked offers it to the lead creature, using the Bag's chapbook flow ("which move makes way?") when it is full.

const ROSETTES := ["", "Bronze", "Silver", "Gold"]

static func after_game(host: Node, game_id: String, score: float) -> void:
	if host == null or not is_instance_valid(host) or PartyPieces.entry(game_id).is_empty():
		return
	var e := PartyPieces.entry(game_id)
	var r := PartyPieces.record(Game.data, game_id, score)
	var rose := int(r.rosette)
	if rose > 0:
		Audio.sfx("badge" if rose >= 2 else "confirm")
		var line := "%s rosette for %s." % [ROSETTES[rose], str(e.name).to_lower()]
		if rose == 3:
			line = "Gold rosette! You beat %s at %s. A prize of %s." % [e.master_name, str(e.name).to_lower(), UIKit.money_text(int(r.prize))]
		if not r.unlocked or rose == 3:   # a first-time gold also unlocks: tell them about the prize before the offer
			await _toast(host, line)
	if r.unlocked:
		await _offer(host, game_id)

## The Almanac's re-teach and the unlock offer both end here: teach `game_id`'s piece to party member `idx`.
## Returns true if the creature now knows it.
static func teach(host: Node, game_id: String, idx: int) -> bool:
	var c: Creature = Game.data.party[idx]
	var move_id := PartyPieces.move_of(game_id)
	if not PartyPieces.can_learn(c, game_id, Game.moves):
		return false
	if c.moves.size() < Rules.MAX_MOVES:
		Progression.relearn(c, move_id, 0, Game.moves)
		Audio.sfx("heal")
		return true
	var res = await host.open_child("relearn:teach:%d:%s" % [idx, move_id])
	return res is Dictionary

static func _offer(host: Node, game_id: String) -> void:
	var e := PartyPieces.entry(game_id)
	var mname := str(Game.moves.get_move(PartyPieces.move_of(game_id)).get("name", "a move"))
	var lead: Creature = Game.data.party[0] if not Game.data.party.is_empty() else null
	if lead == null:
		return
	var who := lead.display_name()
	var head := "Silver rosette for %s! %s watched every go." % [str(e.name).to_lower(), who]
	if lead.has_move(PartyPieces.move_of(game_id)):
		await _toast(host, head + " It already knows %s." % mname)
		return
	if not PartyPieces.can_learn(lead, game_id, Game.moves):
		await _toast(host, head + " %s cannot learn %s, but someone else in the party might. See the Almanac, Party Pieces page." % [who, mname])
		return
	var pick: int = await _choose(host, head + " Teach it %s?" % mname, ["Teach it", "Not now"])
	if pick != 0:
		await _toast(host, "%s is saved in the Almanac, Party Pieces page, to teach any time." % mname)
		return
	var ok: bool = await teach(host, game_id, 0)
	await _toast(host, ("%s learned %s!" % [who, mname]) if ok else ("%s did not learn %s. Try again from the Almanac." % [who, mname]))

static func _toast(host: Node, text: String) -> void:
	await _choose(host, text, ["OK"])

## A modal card on the host with buttons; returns the index chosen.
static func _choose(host: Node, text: String, options: Array) -> int:
	var locked_before = host.get("_locked")
	host.set("_locked", true)
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var card := UIKit.panel(Color("1d2230f8"), 22)
	card.custom_minimum_size = Vector2(760, 0)
	layer.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	card.add_child(col)
	var l := UIKit.label(text, 28, UIKit.CREAM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(716, 0)  # a known wrap width, or the card measures one word per line
	col.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	var done := [-1]
	var btns := []
	for i in options.size():
		var b := UIKit.button(str(options[i]), 200)
		b.pressed.connect(func(): done[0] = i)
		row.add_child(b)
		btns.append(b)
	UIKit.wrap_focus(btns)
	host.add_child(layer)
	card.reset_size()
	card.position = ((layer.get_viewport_rect().size - card.size) / 2.0).floor()
	UIKit.focus_later(btns[0])
	var tree: SceneTree = host.get_tree()
	while done[0] < 0 and is_instance_valid(layer):
		await tree.process_frame
	if is_instance_valid(layer):
		Audio.sfx("confirm")
		layer.queue_free()
	await tree.process_frame
	if is_instance_valid(host):
		host.set("_locked", locked_before if locked_before != null else false)
	return maxi(0, done[0])
