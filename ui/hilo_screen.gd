extends CasinoBase
## Higher or Lower (see HigherLower): call the next card, your pot grows by the price shown, cash out when you like.
## A tie loses; aces are high. The whole run of cards is dealt (and saved) when the stake goes down.

const CARD := Vector2(150, 212)

var _game: HigherLower
var _stage: Control
var _cur: Dictionary = {}
var _prev: Dictionary = {}
var _slide := 1.0     # 0..1: the new card sliding over the old
var _hi_btn: Button
var _lo_btn: Button
var _cash_btn: Button
var _deal_btn: Button
var _pot_l: Label
var _ladder: HBoxContainer
var _busy := false

func _build() -> void:
	set_title("Higher or Lower")
	stakes = [5, 10, 25, 50, 100, 250]
	stake_i = 1
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 22)
	content.add_child(root)
	var felt := felt_panel(Color("1d2a4a"), BRASS, 16)
	felt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(felt)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 6)
	felt.add_child(fv)
	_pot_l = serif(40, UIKit.GOLD)
	_pot_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fv.add_child(_pot_l)
	_stage = Control.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	fv.add_child(_stage)
	_ladder = HBoxContainer.new()
	_ladder.alignment = BoxContainer.ALIGNMENT_CENTER
	_ladder.add_theme_constant_override("separation", 6)
	fv.add_child(_ladder)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(340, 0)
	side.add_theme_constant_override("separation", 10)
	root.add_child(side)
	var rules := UIKit.label("Call the next card. A right call multiplies your pot by its price; a wrong one, or a tie, and it's gone. Aces high. Up to ten calls.", 20, UIKit.MUTED)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(rules)
	side.add_child(stake_picker())
	_deal_btn = make_button("Deal a card", _deal, 340)
	_hi_btn = make_button("Higher", _call.bind("higher"), 340)
	_lo_btn = make_button("Lower", _call.bind("lower"), 340)
	_cash_btn = make_button("Cash out", _cash, 340)
	for b in [_deal_btn, _hi_btn, _lo_btn, _cash_btn]:
		side.add_child(b)
	side.add_child(make_button("Leave the table", func(): _on_cancel(), 340))
	fit_side(side)
	_update()
	UIKit.focus_later(_deal_btn)

func setup(arg: String) -> void:
	_dev = arg.begins_with("dev")
	if arg == "dev:play":  # screenshots: a hand already under way
		get_tree().create_timer(0.6).timeout.connect(_deal)

func _live() -> bool:
	return _game != null and not _game.done

func _update() -> void:
	var live := _live()
	_deal_btn.disabled = _busy or live
	_hi_btn.disabled = _busy or not live
	_lo_btn.disabled = _busy or not live
	_cash_btn.disabled = _busy or not live
	if live:
		var r := int(_game.card().rank)
		for pair in [[_hi_btn, "higher", "Higher"], [_lo_btn, "lower", "Lower"]]:
			var m := HigherLower.multiplier(pair[1], r)
			pair[0].text = "%s     x%.2f   (%d%%)" % [pair[2], m, roundi(HigherLower.chance(pair[1], r) * 100)] if m > 0 else "%s     can't win" % pair[2]
			if m <= 0:
				pair[0].disabled = true
		_cash_btn.text = "Cash out  %s" % Purse.text(_game.returns())
		_pot_l.text = "Pot  " + Purse.text(int(floor(_game.pot)))
	else:
		_hi_btn.text = "Higher"
		_lo_btn.text = "Lower"
		_cash_btn.text = "Cash out"
		_pot_l.text = "Stake  " + Purse.text(stake())
	UIKit.clear(_ladder)
	var steps := _game.steps if _game != null else 0
	for k in HigherLower.MAX_STEPS:
		var dot := PanelContainer.new()
		var on := k < steps
		dot.add_theme_stylebox_override("panel", UIKit.box(UIKit.GOLD if on else Color("2c3446"), BRASS if on else Color("5a5f6e"), 2, 10, 0))
		dot.custom_minimum_size = Vector2(26, 14)
		_ladder.add_child(dot)
	set_hints([["confirm", "Choose"], ["leftright", "Stake"], ["cancel", "Leave"]] if not live else [["updown", "Choose"], ["confirm", "Call"], ["cancel", "Cash out"]])
	_stage.queue_redraw()

func _deal() -> void:
	if _busy or _live():
		return
	if not take_stake(stake()):
		return
	_game = HigherLower.new(Punt.rng(Game.data, "hilo"), stake())
	commit()  # every card of the run is dealt and saved
	_prev = {}
	_cur = _game.card()
	await _slide_in()
	_update()
	UIKit.focus_later(_hi_btn if not _hi_btn.disabled else _lo_btn)

func _slide_in() -> void:
	_busy = true
	_slide = 0.0
	Audio.sfx_at("cursor", -2.0, 1.3)
	var tw := create_tween()
	tw.tween_method(_set_slide, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tw.finished
	_busy = false

func _set_slide(v: float) -> void:
	_slide = v
	_stage.queue_redraw()

func _call(g: String) -> void:
	if _busy or not _live():
		return
	var nxt := _game.next_card()
	var right := _game.guess(g)
	_prev = _cur
	_cur = nxt
	await _slide_in()
	if right:
		Audio.sfx("stat_up")
		if _game.done:
			settle(_game.stake, _game.returns(), "Ten in a row! %s" % Purse.text(_game.returns()))
	else:
		settle(_game.stake, 0, "Tie! House wins." if int(nxt.rank) == int(_prev.rank) else "Wrong call!")
	_update()
	UIKit.focus_later(_deal_btn if not _live() else (_hi_btn if not _hi_btn.disabled else _lo_btn))

func _cash() -> void:
	if _busy or not _live():
		return
	var back := _game.cash_out()
	settle(_game.stake, back, "Cashed out  %s" % Purse.text(back) if _game.steps > 0 else "Stake back")
	_update()
	UIKit.focus_later(_deal_btn)

func _draw_stage() -> void:
	var r := _stage.get_rect()
	var c := Vector2(r.size.x * 0.5, r.size.y * 0.5)
	var at := c - CARD * 0.5
	if _cur.is_empty():
		CasinoBase.draw_card(_stage, Rect2(at, CARD), {}, false)
		return
	if not _prev.is_empty():
		var pr := Rect2(at - Vector2(CARD.x * 0.9 * _slide, 0) + Vector2(0, 8 * _slide), CARD)
		_stage.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		CasinoBase.draw_card(_stage, pr, _prev, true)
		_stage.draw_rect(pr, Color(0, 0, 0, 0.35 * _slide))
	var x := lerpf(r.size.x + CARD.x, at.x, _slide)
	CasinoBase.draw_card(_stage, Rect2(Vector2(x, at.y), CARD), _cur, true)
	# the next one waiting, face down, on the right
	if _live():
		CasinoBase.draw_card(_stage, Rect2(at + Vector2(CARD.x * 1.15, 14), CARD * 0.85), {}, false)

func _on_cancel() -> void:
	if _busy:
		return
	if _live():
		_cash()  # walking away banks the pot (or hands the stake back before the first call)
		return
	close(null)

func _uses_left_right() -> bool:
	return not _live()
