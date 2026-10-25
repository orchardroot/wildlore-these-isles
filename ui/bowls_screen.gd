extends MenuBase
## Crown green bowls (story command {"do": "bowls"}): three ends against a local, two woods each. On your end you
## roll the jack first: aim with the direction keys (left and right turn, up and down change how far), Confirm to
## roll. Then the woods: the bias bends each wood in as it slows, and the crown shoves it downhill, so aim off the
## line. Swap hand (Run) changes which way the wood curves. Easier bowls steadies your hand and draws the whole
## curve. The numbers live in Bowls. Closes with {"won": bool, "draw": bool, "ends": ends you won} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows an end under way).

const GREEN_PX := 440.0
const TURN := 0.32            # radians per second
const REACH := 9.0            # metres per second the weight changes
const PAUSE := 0.7
const GRASS := Color("3f7a3c")
const GRASS_CROWN := Color("4a8a46")
const MINE := Color("c4523a")
const THEIRS := Color("23201e")

var _venue_id := "waterloo"
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _steady: Dictionary
var _easy := false
var _end := 0
var _my_shots := 0
var _their_shots := 0
var _ends_me := 0
var _jack := Vector2.ZERO
var _jack_down := false
var _mine: Array = []
var _theirs: Array = []
var _phase := "jack"            # jack | aim | rolling | wait | over
var _heading := 0.0             # radians; for woods this is an offset from the bearing to the jack
var _weight := 20.0
var _bias := 1
var _rolling: Dictionary = {}   # {path, end, side ("me"|"them"|"jack"), i}
var _wait := 0.0
var _msg := ""
var _green: Control
var _info: Label
var _hint_l: Label

func _build() -> void:
	set_title("Crown green bowls")
	_easy = Settings.easy_darts
	_steady = Bowls.steadiness(_easy)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)
	_green = Control.new()
	_green.custom_minimum_size = Vector2(GREEN_PX + 10.0, GREEN_PX + 10.0)
	_green.draw.connect(_draw_green)
	root.add_child(_green)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 12)
	root.add_child(side)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_info)
	_hint_l = UIKit.label("", 22, UIKit.GOLD)
	_hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_hint_l)
	set_hints([["confirm", "Roll"], ["run", "Swap hand"], ["cancel", "Walk away"]])
	_wait = 0.4
	_start_end()

func setup(arg: String) -> void:
	_venue_id = arg if Bowls.venue(arg).size() > 0 else "waterloo"
	_rival = Bowls.venue(_venue_id).rival
	_start_end()
	if arg.begins_with("dev"):   # an end part way through, one wood each down
		_rival = Bowls.venue("waterloo").rival
		_end = 1
		_my_shots = 2
		_their_shots = 1
		_ends_me = 1
		_jack = Vector2(1.0, -7.0)
		_jack_down = true
		_mine = [Vector2(-2.8, -4.5)]
		_theirs = [Vector2(-1.5, -8.0)]
		_phase = "aim"
		_msg = "Dennis is holding shot. Your wood."
		_reset_aim()
	_refresh()

func _start_end() -> void:
	if _rival.is_empty():
		_rival = Bowls.venue(_venue_id).rival
	_jack_down = false
	_mine = []
	_theirs = []
	_rolling = {}
	_heading = 0.0
	_weight = 18.0
	if Bowls.jack_setter(_end) == "me":
		_phase = "jack"
		_msg = "Your jack. Aim where you like, then roll it."
	else:
		_jack = Bowls.local_jack(_rng)
		_jack_down = true
		_msg = "%s rolls the jack." % _who()
		_next_wood()
		return
	_refresh()

func _who() -> String:
	return str(_rival.get("who", "The local")).split(",")[0]

func _first() -> String:
	return Bowls.jack_setter(_end)

func _next_wood() -> void:
	var nxt := Bowls.next_to_play(_jack, _mine, _theirs, _first())
	if nxt == "":
		_score()
	elif nxt == "me":
		_phase = "aim"
		_reset_aim()
		if _msg == "" or _msg.begins_with("Your jack"):
			_msg = "Your wood."
		_refresh()
	else:
		var w := Bowls.local_wood(_jack, _rival, _rng)
		_rolling = {"path": w.path, "end": w.end, "side": "them", "i": 0.0, "bias": w.bias}
		_phase = "rolling"
		_refresh()

func _reset_aim() -> void:
	_heading = 0.0
	var d := _jack.distance_to(Bowls.MAT)
	_weight = d
	_bias = 1 if _jack.x < 0.0 else -1

func _score() -> void:
	var r := Bowls.score_end(_jack, _mine, _theirs)
	match str(r.winner):
		"me":
			_my_shots += int(r.shots)
			_ends_me += 1
			_msg = "You take the end: %d shot%s." % [int(r.shots), "" if int(r.shots) == 1 else "s"]
		"them":
			_their_shots += int(r.shots)
			_msg = "%s takes the end: %d shot%s." % [_who(), int(r.shots), "" if int(r.shots) == 1 else "s"]
		_:
			_msg = "Nothing between them. No shots."
	_end += 1
	var st := Bowls.match_state(_my_shots, _their_shots, _end)
	_phase = "wait"
	_wait = PAUSE * 2.5
	_rolling = {}
	if st != "play":
		_phase = "over"
		_msg += " Match to %s." % ("you" if st == "me" else _who()) if st != "draw" else " All square, so a draw."
		_refresh()
		await get_tree().create_timer(1.8).timeout
		close({"won": st == "me", "draw": st == "draw", "ends": _ends_me})
		return
	_refresh()

func _process(delta: float) -> void:
	if _phase == "over":
		return
	_wait = maxf(0.0, _wait - delta)
	match _phase:
		"wait":
			if _wait <= 0.0:
				_start_end()
		"jack", "aim":
			if _wait > 0.0:
				return
			var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if v != Vector2.ZERO:
				_heading = clampf(_heading + v.x * TURN * delta, -0.9, 0.9)
				_weight = clampf(_weight - v.y * REACH * delta, 4.0, 34.0)
				if _phase == "jack":
					_weight = clampf(_weight, Bowls.JACK_MIN, Bowls.JACK_MAX)
				_refresh()
			if Input.is_action_just_pressed("run") and _phase == "aim":
				_bias = -_bias
				_refresh()
			if Input.is_action_just_pressed("confirm"):
				_release()
		"rolling":
			_rolling.i = float(_rolling.i) + delta / Bowls.STEP * 1.6
			var path: PackedVector2Array = _rolling.path
			if int(_rolling.i) >= path.size() - 1:
				_land()
			_green.queue_redraw()

func _release() -> void:
	if _phase == "jack":
		var aim := Bowls.MAT + Bowls.dir_of(_heading) * _weight
		_jack = Bowls.jack_spot(aim)
		_jack_down = true
		Audio.sfx("cursor")
		_msg = "Jack down. %s bowls first." % ("You" if _first() == "me" else _who())
		_next_wood()
		return
	var bearing := atan2(_jack.x - Bowls.MAT.x, -(_jack.y - Bowls.MAT.y))
	var w := Bowls.deliver(Bowls.MAT, bearing + _heading, _weight, _bias, _steady, _rng)
	_rolling = {"path": w.path, "end": w.end, "side": "me", "i": 0.0, "bias": _bias}
	_phase = "rolling"
	Audio.sfx("confirm")
	_refresh()

func _land() -> void:
	var end: Vector2 = _rolling.end
	var side := str(_rolling.side)
	_rolling = {}
	if side == "me":
		_mine.append(end)
	else:
		_theirs.append(end)
	var d := end.distance_to(_jack)
	if Bowls.dead(end):
		_msg = "%s ran off the green. A dead wood." % ("Yours" if side == "me" else _who() + "'s")
	else:
		_msg = "%s: %.1f m from the jack." % ["Your wood" if side == "me" else _who() + "'s wood", d]
	_phase = "between"   # a beat to read the result, then the next wood (or the count)
	_refresh()
	await get_tree().create_timer(PAUSE).timeout
	if _phase == "between":
		_next_wood()

func _on_cancel() -> void:
	if _phase == "over":
		return
	close(null)

func _refresh() -> void:
	if _info == null:
		return
	var end_no := mini(_end + 1, Bowls.ENDS + Bowls.MAX_EXTRA)
	var bias_txt := "curves right" if _bias > 0 else "curves left"
	var lines := "End %d%s\nYou: %d shots\n%s: %d\n\n%s" % [end_no, "" if end_no <= Bowls.ENDS else " (extra)", _my_shots, _who(), _their_shots, _msg]
	if _phase == "aim":
		lines += "\n\nWoods left: %d.  Hand: %s." % [Bowls.WOODS - _mine.size(), bias_txt]
	_info.text = lines
	_hint_l.text = ""
	if _phase == "aim":
		_hint_l.text = "The crown shoves a wood downhill and the bias bends it as it slows. %s" % ("The line shows where it will go." if _easy else "The short line shows where it starts to go.")
	elif _phase == "jack":
		_hint_l.text = "The jack runs true. Left and right turn it, up and down set the length."
	_green.queue_redraw()
	set_hints([["confirm", "Roll"], ["run", "Swap hand"], ["cancel", "Walk away"]] if _phase in ["aim", "jack"] else [["cancel", "Walk away"]])

# ---- drawing (metres to pixels: the crown is the middle of the green control)

func _px(p: Vector2) -> Vector2:
	var c := _green.size * 0.5
	return c + p * (GREEN_PX / (Bowls.HALF * 2.0))

func _draw_green() -> void:
	var s := GREEN_PX
	var c := _green.size * 0.5
	_green.draw_rect(Rect2(c - Vector2(s, s) * 0.5 - Vector2(5, 5), Vector2(s + 10, s + 10)), Color("5b4636"))
	_green.draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), GRASS)
	for i in 4:   # the crown, lighter towards the top of the hump
		var r := (Bowls.CROWN_R * (1.0 - float(i) * 0.24)) * (s / (Bowls.HALF * 2.0))
		_green.draw_circle(c, r, GRASS.lerp(GRASS_CROWN, 0.4 + float(i) * 0.2))
	_green.draw_rect(Rect2(_px(Bowls.MAT) - Vector2(14, 5), Vector2(28, 10)), Color("2b2b2b"))
	if _jack_down:
		_green.draw_circle(_px(_jack), 4.0, Color("f4f0e4"))
		_green.draw_arc(_px(_jack), 4.0, 0.0, TAU, 12, Color.BLACK, 1.5)
	for w in _mine:
		_wood(w, MINE)
	for w in _theirs:
		_wood(w, THEIRS)
	if _phase == "rolling" and not _rolling.is_empty():
		var path: PackedVector2Array = _rolling.path
		var k := mini(int(_rolling.i), path.size() - 1)
		_wood(path[k], MINE if str(_rolling.side) == "me" else THEIRS)
	elif _phase == "aim":
		_draw_aim()
	elif _phase == "jack":
		var to := Bowls.MAT + Bowls.dir_of(_heading) * _weight
		_green.draw_dashed_line(_px(Bowls.MAT), _px(to), Color("f4f0e4"), 2.0, 6.0)
		_green.draw_circle(_px(Bowls.jack_spot(to)), 4.0, Color("f4f0e4"))

func _draw_aim() -> void:
	var bearing := atan2(_jack.x - Bowls.MAT.x, -(_jack.y - Bowls.MAT.y))
	var plan := Bowls.roll_wood(Bowls.MAT, bearing + _heading, _weight, _bias)
	var path: PackedVector2Array = plan.path
	var n := path.size() if _easy else maxi(2, path.size() / 3)
	var pts := PackedVector2Array()
	for i in n:
		pts.append(_px(path[i]))
	if pts.size() >= 2:
		_green.draw_polyline(pts, Color("f4e3a1"), 2.5)
	if _easy:
		_green.draw_circle(_px(plan.end), 5.0, Color("f4e3a1"))
	# the straight marker: where the wood would stop with no bias and no crown, the 'weight' you have dialled in
	var straight := Bowls.MAT + Bowls.dir_of(bearing + _heading) * _weight
	_green.draw_arc(_px(straight), 5.0, 0.0, TAU, 14, Color(1, 1, 1, 0.6), 1.5)
	_wood(Bowls.MAT, MINE)

func _wood(p: Vector2, col: Color) -> void:
	var q := _px(p)
	_green.draw_circle(q, 6.5, col)
	_green.draw_arc(q, 6.5, 0.0, TAU, 14, Color("f0e6c8"), 1.5)
