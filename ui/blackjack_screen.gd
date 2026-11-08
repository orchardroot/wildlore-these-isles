extends CasinoBase
## Blackjack at the Palace (see Blackjack): dealer stands on all 17s, blackjack pays 3 to 2, double on any two.
## The shoe is shuffled and the stake saved the moment you deal.

const CARD := Vector2(96, 136)
const SHOE := Vector2(1040, -30)

class CardView extends Control:
	var card := {}
	var face_up := true
	func _init(c: Dictionary, up: bool) -> void:
		card = c
		face_up = up
		size = Vector2(96, 136)
		pivot_offset = size * 0.5
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		CasinoBase.draw_card(self, Rect2(Vector2.ZERO, size), card, face_up)

var _table: Control
var _game: Blackjack
var _dealer_views: Array = []
var _player_views: Array = []
var _dealer_l: Label
var _player_l: Label
var _deal_btn: Button
var _hit_btn: Button
var _stand_btn: Button
var _double_btn: Button
var _tip: Label
var _busy := false

func _build() -> void:
	set_title("Blackjack")
	stakes = [10, 20, 50, 100, 200, 500]
	stake_i = 0
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 22)
	content.add_child(root)
	var felt := felt_panel(FELT, BRASS, 0)
	felt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(felt)
	_table = Control.new()
	_table.clip_contents = true
	_table.draw.connect(_draw_table)
	felt.add_child(_table)
	_dealer_l = serif(26, UIKit.CREAM)
	_table.add_child(_dealer_l)
	_player_l = serif(26, UIKit.CREAM)
	_table.add_child(_player_l)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(330, 0)
	side.add_theme_constant_override("separation", 10 if not UIKit.big_text() else 4)  # five buttons and Large text
	root.add_child(side)
	var rules := UIKit.label("Double on any two. No splits, no insurance, no arguing with Maureen.", 18, UIKit.MUTED)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(rules)
	side.add_child(stake_picker())
	_deal_btn = make_button("Deal", _deal, 330)
	_hit_btn = make_button("Hit", _hit, 330)
	_stand_btn = make_button("Stand", _stand, 330)
	_double_btn = make_button("Double down", _double, 330)
	for b in [_deal_btn, _hit_btn, _stand_btn, _double_btn]:
		side.add_child(b)
	side.add_child(make_button("Leave the table", func(): _on_cancel(), 330))
	_tip = hand(26, Color("d8cfb4"))
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_tip)
	_update()
	UIKit.focus_later(_deal_btn)

func setup(arg: String) -> void:
	_dev = arg.begins_with("dev")
	if arg == "dev:play":  # screenshots: a hand already under way
		get_tree().create_timer(0.6).timeout.connect(_deal)

func _update() -> void:
	var live := _game != null and not _game.done
	_deal_btn.disabled = _busy or live
	_hit_btn.disabled = _busy or not live
	_stand_btn.disabled = _busy or not live
	_double_btn.disabled = _busy or not live or not _game.can_double() or why_not(_game.stake) != ""
	if _game == null:
		_dealer_l.text = ""
		_player_l.text = ""
	else:
		var dv := Blackjack.value(_game.dealer if _all_dealer_up() else [_game.upcard()])
		_dealer_l.text = "Dealer  %d" % dv.total if _dealer_views.size() > 0 else ""
		var pv := Blackjack.value(_game.player)
		_player_l.text = ("You  %d%s" % [pv.total, "  (soft)" if pv.soft and pv.total < 21 else ""]) if _player_views.size() > 0 else ""
	var was := _tip.text
	_tip.text = ""
	if live and not _busy:
		var advice := Blackjack.basic_strategy(_game)
		_tip.text = "Maureen, the dealer, mutters: \"The book says %s.\"" % {"hit": "hit", "stand": "stand", "double": "double"}[advice]
	if _tip.text != was or not _tip.has_meta("want"):
		fit_side(_tip.get_parent())  # Maureen's line may need the side's words a little smaller (Large text)
	set_hints([["confirm", "Choose"], ["leftright", "Stake"], ["cancel", "Leave"]] if not live else [["updown", "Choose"], ["confirm", "Play"]])

func _all_dealer_up() -> bool:
	for v in _dealer_views:
		if not v.face_up:
			return false
	return true

func _layout_labels() -> void:
	_dealer_l.position = Vector2(40, 20)
	_player_l.position = Vector2(40, _table.size.y - 50)

func _slot(dealer: bool, i: int, n: int) -> Vector2:
	var w := _table.size.x
	var spread := 70.0
	var total := CARD.x + spread * (n - 1)
	var x := (w - total) * 0.5 + i * spread
	var y := 66.0 if dealer else _table.size.y - CARD.y - 64.0
	return Vector2(x, y)

func _place(views: Array, dealer: bool) -> void:
	for i in views.size():
		var tw := create_tween()
		tw.tween_property(views[i], "position", _slot(dealer, i, views.size()), 0.18).set_trans(Tween.TRANS_SINE)

## Slides a card out of the shoe to its place.
func _deal_card(c: Dictionary, dealer: bool, up := true) -> void:
	var v := CardView.new(c, up)
	_table.add_child(v)
	v.position = Vector2(_table.size.x - 80, -CARD.y)
	v.rotation = -0.5
	var views := _dealer_views if dealer else _player_views
	views.append(v)
	_place(views.slice(0, views.size() - 1), dealer)
	Audio.sfx_at("cursor", -2.0, 1.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "position", _slot(dealer, views.size() - 1, views.size()), 0.28).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "rotation", 0.0, 0.28)
	await tw.finished
	_update()

func _flip(v: CardView) -> void:
	var tw := create_tween()
	tw.tween_property(v, "scale:x", 0.0, 0.12)
	await tw.finished
	v.face_up = true
	v.queue_redraw()
	var tw2 := create_tween()
	tw2.tween_property(v, "scale:x", 1.0, 0.12)
	await tw2.finished
	_update()

func _clear() -> void:
	for v in _dealer_views + _player_views:
		v.queue_free()
	_dealer_views = []
	_player_views = []

func _deal() -> void:
	if _busy or (_game != null and not _game.done):
		return
	if not take_stake(stake()):
		return
	_game = Blackjack.new(Punt.rng(Game.data, "blackjack"), stake())
	commit()  # the shoe is shuffled and your stake is down: saved
	_busy = true
	_layout_labels()
	_clear()
	await _deal_card(_game.player[0], false)
	await _deal_card(_game.dealer[0], true)
	await _deal_card(_game.player[1], false)
	await _deal_card(_game.dealer[1], true, false)
	_busy = false
	if _game.done:
		await _finish()
	_update()
	UIKit.focus_later(_hit_btn if not _game.done else _deal_btn)

func _hit() -> void:
	if _busy or _game == null or _game.done:
		return
	_busy = true
	_game.hit()
	await _deal_card(_game.player.back(), false)
	_busy = false
	if _game.done:
		await _finish()
	_update()

func _stand() -> void:
	if _busy or _game == null or _game.done:
		return
	_game.stand()
	await _finish()

func _double() -> void:
	if _busy or _game == null or not _game.can_double():
		return
	if not take_stake(_game.stake):
		return
	_busy = true
	_game.double_down()
	await _deal_card(_game.player.back(), false)
	_busy = false
	await _finish()

## Turns the hole card, deals the dealer's draws, and settles.
func _finish() -> void:
	_busy = true
	_update()
	if _dealer_views.size() > 1 and not _dealer_views[1].face_up:
		await get_tree().create_timer(0.25).timeout
		await _flip(_dealer_views[1])
	for i in range(_dealer_views.size(), _game.dealer.size()):
		await get_tree().create_timer(0.35).timeout
		await _deal_card(_game.dealer[i], true)
	var label: String = {"blackjack": "Blackjack!", "win": "You win!", "push": "Push. Stake back.", "lose": "Dealer wins",
		"bust": "Bust!", "dealer_blackjack": "Dealer has blackjack"}.get(_game.result, "")
	if _game.returns() > _game.stake:
		label += "  " + Purse.text(_game.returns())
	settle(_game.stake, _game.returns(), label)
	_busy = false
	_update()
	UIKit.focus_later(_deal_btn)

func _draw_table() -> void:
	var r := _table.get_rect()
	var rad := r.size.x * 0.75
	var c := Vector2(r.size.x * 0.5, r.size.y * 0.5 + 18 - rad)
	var half := asin(clampf(r.size.x * 0.46 / rad, 0.0, 1.0))
	# the printed arc under the strapline
	_table.draw_arc(c, rad, PI * 0.5 - half, PI * 0.5 + half, 64, Color(BRASS, 0.55), 3, true)
	_table.draw_arc(c, rad + 34, PI * 0.5 - half * 0.97, PI * 0.5 + half * 0.97, 64, Color(BRASS, 0.3), 2, true)
	var f: Font = load(SERIF)
	var txt := "BLACKJACK PAYS 3 TO 2"
	var fs := 24
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_table.draw_string(f, Vector2((r.size.x - tw) * 0.5, r.size.y * 0.5 - 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(BRASS, 0.85))
	var t2 := "Dealer stands on all 17s"
	var w2 := f.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	_table.draw_string(f, Vector2((r.size.x - w2) * 0.5, r.size.y * 0.5 + 16), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UIKit.CREAM, 0.55))
	# the shoe, top right
	var shoe := Rect2(r.size.x - 110, 10, 90, 56)
	_table.draw_rect(shoe, Color("2a1f1a"))
	_table.draw_rect(shoe, BRASS, false, 2)
	_table.draw_rect(Rect2(shoe.position + Vector2(10, 8), Vector2(70, 40)), CLARET)
	# your chips in the betting circle
	var bc := Vector2(r.size.x - 70, r.size.y - 60)
	_table.draw_arc(bc, 26, 0, TAU, 32, Color(UIKit.CREAM, 0.5), 2, true)
	if _game != null and not _game.done:
		CasinoBase.draw_chip(_table, bc, 20, _game.stake)

func _process(_d: float) -> void:
	if _table and _table.size.x > 0 and _dealer_l.position == Vector2.ZERO:
		_layout_labels()
		_table.queue_redraw()

func _on_cancel() -> void:
	if _busy:
		return
	if _game != null and not _game.done:
		_stand()  # walking away mid-hand stands, it doesn't forfeit
		return
	close(null)

func _uses_left_right() -> bool:
	return _game == null or _game.done
