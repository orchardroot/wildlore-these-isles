extends MenuBase
## A game of Trumps (story command {"do": "trumps"}, menu "trumps:<zone>:<npc>"). Your front card on the left, theirs
## face down on the right. When you lead, pick a stat (Up/Down then Confirm, or click a row); when they lead they pick
## one for their card. Their card flips, the higher number wins the pair and the winner takes both cards. Twelve
## rounds or until a hand is empty, most cards wins. Closes with {"won": bool} ({"quit": true} if walked out).
## setup arg: "<zone>:<npc>" (the opponent's hand is Trumps.deck), or "dev" for a dev deck, one round already played.

const BEAT := 0.9
const SMALL_SCALE := 0.58

var _zone := ""
var _npc := ""
var _who := "Your opponent"
var _g: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _mine: TrumpCard
var _theirs: TrumpCard
var _holder_l: Control
var _holder_r: Control
var _msg: Label
var _score: Label
var _round_l: Label
var _lead_l: Label
var _their_strip: HBoxContainer
var _my_strip: HBoxContainer
var _their_head: Label
var _my_head: Label
var _sel := 0
var _phase := "wait"     # wait, pick, busy, over
var _started := false

func _build() -> void:
	set_title("Trumps")
	Trumps.use_dex(Game.dex)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	content.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.custom_minimum_size = Vector2(0, 82)
	root.add_child(top)
	_their_head = UIKit.label("", 22, UIKit.MUTED)
	_their_head.custom_minimum_size = Vector2(220, 0)
	_their_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_their_head)
	_their_strip = HBoxContainer.new()
	_their_strip.add_theme_constant_override("separation", 4)
	top.add_child(_their_strip)
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 26)
	root.add_child(mid)
	_holder_l = _holder()
	mid.add_child(_holder_l)
	var centre := VBoxContainer.new()
	centre.custom_minimum_size = Vector2(380, 0)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 10)
	mid.add_child(centre)
	_round_l = UIKit.label("", 20, UIKit.MUTED)
	_round_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_round_l)
	_score = UIKit.label("", 46, UIKit.GOLD)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_score)
	_lead_l = UIKit.label("", 20, UIKit.CREAM)
	_lead_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_lead_l)
	var mp := UIKit.panel(Color("14182299"), 12)
	mp.custom_minimum_size = Vector2(0, 112)
	centre.add_child(mp)
	_msg = UIKit.label("", 22, UIKit.CREAM)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mp.add_child(_msg)
	_holder_r = _holder()
	mid.add_child(_holder_r)
	var bot := HBoxContainer.new()
	bot.add_theme_constant_override("separation", 14)
	bot.custom_minimum_size = Vector2(0, 82)
	root.add_child(bot)
	_my_head = UIKit.label("Your hand", 22, UIKit.CREAM)
	_my_head.custom_minimum_size = Vector2(220, 0)
	_my_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot.add_child(_my_head)
	_my_strip = HBoxContainer.new()
	_my_strip.add_theme_constant_override("separation", 4)
	bot.add_child(_my_strip)
	_mine = TrumpCard.new(true)
	_theirs = TrumpCard.new(true)
	_holder_l.add_child(_mine)
	_holder_r.add_child(_theirs)
	_mine.stat_chosen.connect(_on_stat_click)
	_mine.stat_hovered.connect(_on_stat_hover)
	set_hints([["updown", "Choose a stat"], ["confirm", "Play it"], ["cancel", "Walk away"]])
	if _g.is_empty():
		_start_game()

func _holder() -> Control:
	var h := Control.new()
	h.custom_minimum_size = TrumpCard.FULL + Vector2(12, 8)
	return h

func setup(arg: String) -> void:
	var p := arg.split(":", true, 1)
	if arg == "dev" or arg == "":
		_zone = "dev"
		_who = "Maureen from the Tram Shelter"
		var d: GameStateData = Game.data
		var hand := ["spikkin", "kindlet", "holtling", "binfox", "hootlet"]
		for s in hand:
			Trumps.give(d, s)
		_g = Trumps.new_game(hand, ["bramblehog", "emberdrey", "redbreast", "snowhare", "gritling"], true)
		Trumps.play(_g, "grit")  # one round already played, so the table shows a game under way
		_g.lead = "mine"
	else:
		_zone = p[0]
		_npc = p[1] if p.size() > 1 else ""
		_who = _resident_name()
		var mine := Trumps.best_hand(Game.data)
		var theirs := Trumps.deck(_zone, _npc, maxi(1, mine.size()))
		_g = Trumps.new_game(mine, theirs, true)
	if content != null:
		_start_game()

func _resident_name() -> String:
	var z := ZoneData.load_id(_zone)
	for n in z.npcs:
		if str(n.get("id", "")) == _npc:
			return str(n.get("name", "Your opponent"))
	return "Your opponent"

func _start_game() -> void:
	if _started or _g.is_empty():
		return
	_started = true
	_their_head.text = _who
	_refresh(false)
	_msg.text = "%s deals. %s" % [_who.split(" ")[0], "You lead." if _g.lead == "mine" else "They lead."]
	if _zone != "dev":
		await get_tree().create_timer(0.5).timeout
	_next_turn()

func _refresh(reveal_theirs: bool) -> void:
	_set_card(_mine, _g.mine, true)
	_set_card(_theirs, _g.theirs, reveal_theirs)
	_mine.position = Vector2(6, 0)
	_theirs.position = Vector2(6, 0)
	_mine.modulate = Color.WHITE
	_theirs.modulate = Color.WHITE
	_mine.scale = Vector2.ONE
	_theirs.scale = Vector2.ONE
	_fill_strip(_their_strip, _g.theirs, false)
	_fill_strip(_my_strip, _g.mine, true)
	_score.text = "%d : %d" % [_g.mine.size(), _g.theirs.size()]
	_round_l.text = "Round %d of %d" % [mini(int(_g.round) + 1, Trumps.MAX_ROUNDS), Trumps.MAX_ROUNDS]
	_lead_l.text = "You lead" if _g.lead == "mine" else "%s leads" % _who.split(" ")[0]
	_their_head.text = "%s\n%d card%s" % [_who, _g.theirs.size(), "" if _g.theirs.size() == 1 else "s"]
	_my_head.text = "Your hand\n%d card%s" % [_g.mine.size(), "" if _g.mine.size() == 1 else "s"]

func _set_card(c: TrumpCard, hand: Array, up: bool) -> void:
	c.visible = not hand.is_empty()
	if hand.is_empty():
		return
	c.show_card(str(hand[0]), up)
	c.set_face(up)

func _fill_strip(strip: HBoxContainer, hand: Array, up: bool) -> void:
	UIKit.clear(strip)
	for i in hand.size():
		var holder := Control.new()
		var sz := TrumpCard.SMALL * SMALL_SCALE
		holder.custom_minimum_size = sz
		var c := TrumpCard.new(false)
		c.scale = Vector2(SMALL_SCALE, SMALL_SCALE)
		c.pivot_offset = Vector2.ZERO
		holder.add_child(c)
		strip.add_child(holder)
		c.show_card(str(hand[i]), up and true)
		c.set_face(up)
		if i == 0:
			c.modulate = Color(1, 1, 1, 1)
		else:
			c.modulate = Color(0.82, 0.82, 0.9, 1)

# ---- turns

func _next_turn() -> void:
	if Trumps.over(_g):
		_finish()
		return
	_mine.set_locked(_g.tried)
	if _g.lead == "mine":
		_phase = "pick"
		_sel = _first_open(0)
		_mine.picking = true
		_mine.set_selected(Trumps.STATS[_sel])
		_msg.text = "Your lead. Pick a stat for %s." % _name_of(_g.mine[0]) if _g.tried.is_empty() else "A tie. Pick another stat."
		set_hints([["updown", "Choose a stat"], ["confirm", "Play it"], ["cancel", "Walk away"]])
	else:
		_phase = "busy"
		_mine.picking = false
		_msg.text = "%s is choosing..." % _who.split(" ")[0] if _g.tried.is_empty() else "A tie. %s picks again..." % _who.split(" ")[0]
		await get_tree().create_timer(BEAT).timeout
		if _done:
			return
		var stat := Trumps.ai_pick(_g, _rng)
		_mine.set_selected(stat)
		_msg.text = "%s picks %s." % [_who.split(" ")[0], str(Trumps.STAT_NAMES[stat])]
		Audio.sfx("cursor")
		await get_tree().create_timer(BEAT).timeout
		_resolve(stat)

func _name_of(id: Variant) -> String:
	return str(Trumps.dex().get_species(str(id)).get("name", id))

func _first_open(from: int) -> int:
	for k in Trumps.STATS.size():
		var i := (from + k) % Trumps.STATS.size()
		if Trumps.STATS[i] not in _g.tried:
			return i
	return 0

func _step(d: int) -> void:
	var i := _sel
	for k in Trumps.STATS.size():
		i = posmod(i + d, Trumps.STATS.size())
		if Trumps.STATS[i] not in _g.tried:
			break
	_sel = i
	_mine.set_selected(Trumps.STATS[_sel])
	Audio.sfx("cursor")

func _on_stat_hover(stat: String) -> void:
	if _phase != "pick":
		return
	var i := Trumps.STATS.find(stat)
	if i != _sel:
		_sel = i
		_mine.set_selected(stat)
		Audio.sfx("cursor")

func _on_stat_click(stat: String) -> void:
	if _phase != "pick":
		return
	_sel = Trumps.STATS.find(stat)
	_mine.set_selected(stat)
	_confirm_pick()

func _input(event: InputEvent) -> void:
	if _phase == "pick" and not _done:
		if event.is_action_pressed("move_up", true):
			get_viewport().set_input_as_handled()
			_step(-1)
			return
		if event.is_action_pressed("move_down", true):
			get_viewport().set_input_as_handled()
			_step(1)
			return
		if event.is_action_pressed("confirm"):
			get_viewport().set_input_as_handled()
			_confirm_pick()
			return
	super._input(event)

func _confirm_pick() -> void:
	if _phase != "pick":
		return
	_phase = "busy"
	_mine.picking = false
	Audio.sfx("confirm")
	_resolve(Trumps.STATS[_sel])

func _resolve(stat: String) -> void:
	_phase = "busy"
	var mine_id: String = _g.mine[0]
	var theirs_id: String = _g.theirs[0]
	await _flip(_theirs, theirs_id)
	var res := Trumps.play(_g, stat)
	var sn := str(Trumps.STAT_NAMES[stat])
	_mine.set_selected(stat)
	_theirs.set_selected(stat)
	match str(res.result):
		"win":
			_mine.set_marks({stat: "win"})
			_theirs.set_marks({stat: "lose"})
			_msg.text = "%s: %d beats %d. You take %s!" % [sn, res.mine, res.theirs, _name_of(theirs_id)]
			Audio.sfx("item")
		"lose":
			_mine.set_marks({stat: "lose"})
			_theirs.set_marks({stat: "win"})
			_msg.text = "%s: %d loses to %d. %s takes %s." % [sn, res.mine, res.theirs, _who.split(" ")[0], _name_of(mine_id)]
			Audio.sfx("bump")
		"tie":
			_mine.set_marks({stat: "tie"})
			_theirs.set_marks({stat: "tie"})
			_msg.text = "%s: %d each. A tie! The leader picks again." % [sn, res.mine]
		_:
			_msg.text = "Nothing between them on any stat. Back to the bottom of the pack."
	await get_tree().create_timer(BEAT * 1.6).timeout
	if _done:
		return
	if str(res.result) in ["win", "lose"]:
		await _slide(str(res.result) == "win")
	else:
		_mine.set_marks({})
	_refresh(false)
	_next_turn()

func _flip(card: TrumpCard, species_id: String) -> void:
	var tw := create_tween()
	tw.tween_property(card, "scale:x", 0.0, 0.14)
	await tw.finished
	card.show_card(species_id, true)
	card.set_face(true)
	card.picking = false
	var tw2 := create_tween()
	tw2.tween_property(card, "scale:x", 1.0, 0.14)
	await tw2.finished
	Audio.sfx("cursor")

## The losing card slides across to the winner's side while it fades.
func _slide(i_won: bool) -> void:
	var loser: TrumpCard = _theirs if i_won else _mine
	var dest := Vector2(-(TrumpCard.FULL.x + 120.0) if i_won else TrumpCard.FULL.x + 120.0, 0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(loser, "position", loser.position + dest, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(loser, "modulate:a", 0.0, 0.42)
	tw.tween_property(loser, "scale", Vector2(0.55, 0.55), 0.42)
	await tw.finished

func _finish() -> void:
	_phase = "over"
	_mine.picking = false
	var w := Trumps.winner(_g)
	var won := w == "mine"
	_refresh(false)
	_mine.visible = false
	_theirs.visible = false
	match w:
		"mine":
			_msg.text = "You win, %d cards to %d. Well played." % [_g.mine.size(), _g.theirs.size()]
			Audio.sfx("item")
		"theirs":
			_msg.text = "%s wins, %d cards to %d. Next time." % [_who.split(" ")[0], _g.theirs.size(), _g.mine.size()]
		_:
			_msg.text = "Level on %d cards each. Honour is satisfied. Nobody believes that." % _g.mine.size()
	set_hints([["confirm", "Done"]])
	await get_tree().create_timer(1.0).timeout
	_phase = "end"
	set_hints([["confirm", "Done"], ["cancel", "Done"]])

func _unhandled_input(event: InputEvent) -> void:
	if _phase == "end" and event.is_action_pressed("confirm") and not _done:
		get_viewport().set_input_as_handled()
		close({"won": Trumps.winner(_g) == "mine", "dev": _zone == "dev"})

func _on_cancel() -> void:
	if _phase == "end":
		close({"won": Trumps.winner(_g) == "mine"})
	elif _phase == "over":
		return
	else:
		close({"won": false, "quit": true})
