extends CasinoBase
## European single-zero roulette (see Roulette). Put chips on the felt (inside bets by picking a number with the bet
## type you want, outside bets on the boxes), then spin. The number is drawn, and saved, before the ball is thrown.

const CELL := Vector2(57, 58)
const TYPES := ["straight", "split_across", "split_up", "street", "corner", "line"]
const TYPE_NAMES := {"straight": "Straight up (35 to 1)", "split_across": "Split, with the next along (17 to 1)",
	"split_up": "Split, with the one above (17 to 1)", "street": "Street of three (11 to 1)",
	"corner": "Corner of four (8 to 1)", "line": "Six line (5 to 1)"}

var _wheel: Control
var _felt: Control
var _chips_layer: Control
var _spots := {}            # number (int) or outside bet kind (String) -> Button
var _bets: Array = []       # {bet, stake}
var _type_i := 0
var _type_btn: Button
var _spin_btn: Button
var _info: Label
var _angle := 0.0           # wheel rotation
var _ball := 0.0            # ball angle
var _ball_r := 1.0          # ball radius, as a fraction (1 = the rim, 0.78 = in a pocket)
var _result := -1
var _spinning := false
var _history: Array = []
var _hist_l: HBoxContainer

func _build() -> void:
	set_title("Roulette")
	stakes = [5, 10, 25, 50, 100]
	stake_i = 0
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	content.add_child(root)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(320, 0)
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)
	_wheel = Control.new()
	_wheel.custom_minimum_size = Vector2(320, 320)
	_wheel.draw.connect(_draw_wheel)
	left.add_child(_wheel)
	_hist_l = HBoxContainer.new()
	_hist_l.add_theme_constant_override("separation", 4)
	left.add_child(_hist_l)
	left.add_child(stake_picker())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)
	var felt_box := felt_panel(FELT, BRASS, 14)
	right.add_child(felt_box)
	_felt = Control.new()
	_felt.custom_minimum_size = Vector2(CELL.x * 14 + 8, CELL.y * 3 + 98)
	felt_box.add_child(_felt)
	_build_felt()
	_chips_layer = Control.new()
	_chips_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chips_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chips_layer.draw.connect(_draw_chips)
	_felt.add_child(_chips_layer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	right.add_child(row)
	_type_btn = make_button("", _next_type, 420)
	row.add_child(_type_btn)
	_spin_btn = make_button("Spin", _spin, 170)
	row.add_child(_spin_btn)
	row.add_child(make_button("Clear bets", _clear_bets, 170))
	_info = UIKit.label("", 22, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_info)
	_show_type()
	_update()
	set_hints([["confirm", "Place chip"], ["leftright", "Move"], ["=- / +  (LB / RB)", "Stake"], ["cancel", "Leave"]])
	UIKit.focus_later(_spots[17])

func setup(arg: String) -> void:
	_dev = arg == "dev"

func _uses_left_right() -> bool:
	return false  # the arrows walk the felt; the shoulder buttons change the stake

func _unhandled_input(event: InputEvent) -> void:
	if _locked or _done:
		return
	var down := false
	var up := false
	if event is InputEventJoypadButton and event.pressed:
		down = event.button_index == JOY_BUTTON_LEFT_SHOULDER
		up = event.button_index == JOY_BUTTON_RIGHT_SHOULDER
	elif event is InputEventKey and event.pressed and not event.echo:
		down = event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT, KEY_PAGEDOWN]
		up = event.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD, KEY_PAGEUP]
	if down or up:
		change_stake(-1 if down else 1)
		get_viewport().set_input_as_handled()

func _spot(text: String, bg: Color, size: Vector2, at: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = size
	b.add_theme_font_size_override("font_size", 22 if text.is_valid_int() else 18)
	b.add_theme_color_override("font_color", Color("fbf7ec"))
	b.add_theme_color_override("font_focus_color", Color("fbf7ec"))
	b.add_theme_color_override("font_hover_color", Color("fbf7ec"))
	var rest := UIKit.box(bg, Color(UIKit.CREAM, 0.7), 1, 3, 0)
	var on := UIKit.box(bg.lightened(0.15), UIKit.GOLD, 3, 3, 0)
	b.add_theme_stylebox_override("normal", rest)
	b.add_theme_stylebox_override("disabled", rest)
	for st in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, on)
	b.focus_entered.connect(_describe.bind(b))
	b.pressed.connect(cb)
	_felt.add_child(b)
	return b

func _build_felt() -> void:
	var red := Color("a8202e")
	var black := Color("1d1d22")
	var zero := _spot("0", Color("2f7a3a"), Vector2(CELL.x, CELL.y * 3), Vector2(0, 0), _place_number.bind(0))
	_spots[0] = zero
	for col in 12:
		for row in 3:
			var n := Roulette.layout_number(col, row)
			_spots[n] = _spot(str(n), red if Roulette.colour(n) == "red" else black, CELL, Vector2(CELL.x * (col + 1), CELL.y * row), _place_number.bind(n))
	for row in 3:
		var k := 3 - row
		_spots["column%d" % k] = _spot("2 to 1", FELT_DARK, CELL, Vector2(CELL.x * 13, CELL.y * row), _place_outside.bind(Roulette.column(k), "column%d" % k))
	for k in range(1, 4):
		_spots["dozen%d" % k] = _spot(["1st 12", "2nd 12", "3rd 12"][k - 1], FELT_DARK, Vector2(CELL.x * 4, 44), Vector2(CELL.x * (1 + (k - 1) * 4), CELL.y * 3 + 4), _place_outside.bind(Roulette.dozen(k), "dozen%d" % k))
	var outs := [["low", "1-18", Roulette.low()], ["even", "Even", Roulette.even()], ["red", "Red", Roulette.red()],
		["black", "Black", Roulette.black()], ["odd", "Odd", Roulette.odd()], ["high", "19-36", Roulette.high()]]
	for i in outs.size():
		var bg := FELT_DARK
		if outs[i][0] == "red":
			bg = red
		elif outs[i][0] == "black":
			bg = black
		_spots[outs[i][0]] = _spot(outs[i][1], bg, Vector2(CELL.x * 2, 44), Vector2(CELL.x * (1 + i * 2), CELL.y * 3 + 50), _place_outside.bind(outs[i][2], outs[i][0]))
	# arrow-key neighbours follow the grid (Godot's own guess works well for a regular layout)

func _next_type() -> void:
	_type_i = (_type_i + 1) % TYPES.size()
	_show_type()

func _show_type() -> void:
	_type_btn.text = "Bet type:  " + TYPE_NAMES[TYPES[_type_i]]
	_type_btn.add_theme_font_size_override("font_size", UIKit.fit_size(_type_btn.text, 420 - 24, UIKit.sized(28), UIKit.MIN_TEXT))  # never wider than its 420 px

## The inside bet the current type makes from number `n`, or {} if there isn't one there.
func _inside(n: int) -> Dictionary:
	match TYPES[_type_i]:
		"straight":
			return Roulette.straight(n)
		"split_across":
			return Roulette.split(n, n + 3) if n > 0 else {}
		"split_up":
			return Roulette.split(n, n + 1) if n > 0 and n % 3 != 0 else {}
		"street":
			return Roulette.street(n - (n - 1) % 3) if n > 0 else {}
		"corner":
			return Roulette.corner(n) if n > 0 else {}
		"line":
			return Roulette.line(n - (n - 1) % 3) if n > 0 and n <= 33 else {}
	return {}

func _place_number(n: int) -> void:
	var b := _inside(n)
	if b.is_empty():
		Audio.sfx("bump")
		_info.text = "No %s from %d. Try another number, or another bet type." % [TYPE_NAMES[TYPES[_type_i]].split(" (")[0].to_lower(), n]
		return
	_add_bet(b)

func _place_outside(bet: Dictionary, _key: String) -> void:
	_add_bet(bet)

func _add_bet(b: Dictionary) -> void:
	if _spinning:
		return
	var total := _total() + stake()
	var why := why_not(total)
	if why != "":
		Audio.sfx("bump")
		_info.text = why
		return
	for e in _bets:
		if e.bet.label == b.label:
			e.stake += stake()
			_after_bet()
			return
	_bets.append({"bet": b, "stake": stake()})
	_after_bet()

func _after_bet() -> void:
	Audio.sfx_at("cursor", 2.0, 0.6)
	_chips_layer.queue_redraw()
	_update()

func _clear_bets() -> void:
	if _spinning:
		return
	_bets.clear()
	_chips_layer.queue_redraw()
	_update()

func _total() -> int:
	var t := 0
	for e in _bets:
		t += int(e.stake)
	return t

func _update() -> void:
	_spin_btn.disabled = _spinning or _bets.is_empty()
	if not _spinning:
		_info.text = ("On the table: %s across %d bet%s." % [Purse.text(_total()), _bets.size(), "" if _bets.size() == 1 else "s"]) if not _bets.is_empty() else "Place your bets. Pick a number for an inside bet, or a box for an outside one."

func _describe(b: Button) -> void:
	Audio.sfx("cursor")
	if _spinning:
		return
	for k in _spots:
		if _spots[k] == b and k is int:
			var bet := _inside(int(k))
			if not bet.is_empty():
				_info.text = "%s pays %d to 1." % [bet.label, Roulette.pays(bet)]

func _spin() -> void:
	if _spinning or _bets.is_empty():
		return
	var total := _total()
	if not take_stake(total):
		return
	_result = Roulette.spin(Punt.rng(Game.data, "roulette"))
	commit()  # the number's drawn and your chips are down: saved before the ball is thrown
	_spinning = true
	_update()
	_info.text = "No more bets!"
	Audio.sfx("bike_bell")
	# the wheel turns one way, the ball the other, and it drops into the drawn pocket
	var pocket := Roulette.WHEEL.find(_result)
	var start_wheel := _angle
	var end_wheel := start_wheel + TAU * 2.0
	var slot := TAU / 37.0
	var end_ball := end_wheel + pocket * slot - TAU * 4.0
	var start_ball := _ball
	_ball_r = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v): _angle = v, start_wheel, end_wheel, 4.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): _ball = v, start_ball, end_ball, 4.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): _ball_r = v, 1.0, 0.74, 1.2).set_delay(2.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for k in 7:
		tw.tween_callback(func(): Audio.sfx_at("cursor", -6.0, 1.6)).set_delay(2.6 + k * 0.17)
	set_process(true)
	await tw.finished
	set_process(false)
	_ball = end_ball
	_ball_r = 0.74
	_wheel.queue_redraw()
	var back := 0
	for e in _bets:
		back += Roulette.returns(e.bet, int(e.stake), _result)
	_history.push_front(_result)
	_history = _history.slice(0, 10)
	_show_history()
	_spinning = false
	var label := "%d %s" % [_result, Roulette.colour(_result).capitalize()]
	settle(total, back, label + ("   You win %s!" % Purse.text(back) if back > 0 else ""))
	_bets.clear()
	_chips_layer.queue_redraw()
	_update()
	_info.text = "%d, %s. %s" % [_result, Roulette.colour(_result), "Winners paid." if back > 0 else "The house thanks you."]
	_flash_spot(_result)

func _flash_spot(n: int) -> void:
	var b: Button = _spots.get(n)
	if b == null:
		return
	var tw := create_tween().set_loops(3)
	tw.tween_property(b, "modulate", Color(1.6, 1.4, 0.8), 0.18)
	tw.tween_property(b, "modulate", Color.WHITE, 0.18)

func _show_history() -> void:
	UIKit.clear(_hist_l)
	for n in _history:
		var col: Color = {"red": Color("a8202e"), "black": Color("1d1d22"), "green": Color("2f7a3a")}[Roulette.colour(n)]
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.box(col, UIKit.CREAM, 1, 4, 2))
		var l := UIKit.label(str(n), 18, Color("fbf7ec"))
		l.custom_minimum_size = Vector2(24, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		_hist_l.add_child(p)

func _process(_d: float) -> void:
	if _spinning:
		_wheel.queue_redraw()

func _draw_chips() -> void:
	for e in _bets:
		var nums: Array = e.bet.numbers
		var c := Vector2.ZERO
		var b: Button = null
		match str(e.bet.kind):
			"straight", "split", "street", "corner", "line":
				for n in nums:
					c += _spots[n].position + _spots[n].size * 0.5
				c /= nums.size()
				if str(e.bet.kind) in ["street", "line"]:
					c.y = CELL.y * 3 - 4  # on the edge of the felt, like a real street bet
			"column":
				b = _spots["column%d" % ((int(nums[0]) - 1) % 3 + 1)]
			"dozen":
				b = _spots["dozen%d" % ((int(nums[0]) - 1) / 12 + 1)]
			_:
				b = _spots[str(e.bet.kind)]
		if b != null:
			c = b.position + b.size * 0.5
		CasinoBase.draw_chip(_chips_layer, c, 16, int(e.stake))

func _draw_wheel() -> void:
	var c := _wheel.size * 0.5
	var R := minf(c.x, c.y) - 6
	_wheel.draw_circle(c + Vector2(3, 5), R + 4, Color(0, 0, 0, 0.4))
	_wheel.draw_circle(c, R + 4, Color("4a2a1a"))
	_wheel.draw_circle(c, R, Color("6a3c22"))
	_wheel.draw_arc(c, R, 0, TAU, 72, BRASS, 3, true)
	var slot := TAU / 37.0
	var r_out := R * 0.86
	var r_in := R * 0.62
	var f: Font = ThemeDB.fallback_font
	for i in 37:
		var a0 := _angle + i * slot - slot * 0.5 - PI * 0.5
		var a1 := a0 + slot
		var n: int = Roulette.WHEEL[i]
		var col: Color = {"red": Color("a8202e"), "black": Color("1d1d22"), "green": Color("2f7a3a")}[Roulette.colour(n)]
		var pts := PackedVector2Array([c + Vector2(cos(a0), sin(a0)) * r_in, c + Vector2(cos(a0), sin(a0)) * r_out,
			c + Vector2(cos(a1), sin(a1)) * r_out, c + Vector2(cos(a1), sin(a1)) * r_in])
		_wheel.draw_colored_polygon(pts, col)
		_wheel.draw_line(pts[0], pts[1], Color(BRASS, 0.7), 1.0)
		var mid := a0 + slot * 0.5
		var tp := c + Vector2(cos(mid), sin(mid)) * (r_out - 12)
		_wheel.draw_set_transform(tp, mid + PI * 0.5, Vector2.ONE)
		var t := str(n)
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_wheel.draw_string(f, Vector2(-w * 0.5, 4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fbf7ec"))
		_wheel.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# the cone and turret
	_wheel.draw_circle(c, r_in, Color("7a4a2a"))
	_wheel.draw_circle(c, r_in * 0.7, Color("8a5a32"))
	for k in 4:
		var a := _angle + k * PI * 0.5
		_wheel.draw_line(c, c + Vector2(cos(a), sin(a)) * r_in * 0.6, BRASS, 5.0)
	_wheel.draw_circle(c, 12, BRASS)
	_wheel.draw_circle(c, 6, BRASS.lightened(0.3))
	# the ball
	var br := lerpf(R * 0.94, R * 0.74, (1.0 - _ball_r) / 0.26) if _ball_r < 1.0 else R * 0.94
	if _result >= 0 or _spinning:
		var bpos := c + Vector2(cos(_ball - PI * 0.5), sin(_ball - PI * 0.5)) * br
		_wheel.draw_circle(bpos + Vector2(1, 2), 7, Color(0, 0, 0, 0.4))
		_wheel.draw_circle(bpos, 7, Color("f6f3ea"))
		_wheel.draw_circle(bpos - Vector2(2, 2), 2.5, Color.WHITE)

func _on_cancel() -> void:
	if _spinning:
		return
	close(null)  # chips still on the felt were never staked: they come home with you
