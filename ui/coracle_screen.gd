extends MenuBase
## Coracle racing (story command {"do": "coracle"}): paddle a round boat down the river and through the buoys.
## Left and Right paddle on that side, which also turns the boat the other way, so alternate to go straight; paddle
## one side and it spins. Confirm braces the paddle and stops the spin. A missed gate costs three seconds. Your time
## against the local's, who paddles a ghost coracle alongside. Easier minigames widen the gates and calm the spin.
## The numbers live in Coracle. Closes with {"won": bool, "time": float} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a race part way through).

const STAGE := Vector2(1184, 400)
const PX := 9.0                 # pixels per metre
const OX := 46.0
const OY := 230.0               # screen y of the river's mid line (y = 28 m)
const MID_M := 28.0
const COUNT := 3.0

var _venue_id := "ironbridge"
var _venue: Dictionary = {}
var _course: Dictionary = {}
var _gates: Array = []
var _s: Dictionary = {}
var _rival: Dictionary = {}
var _their_time := 40.0
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _clock := -COUNT
var _started := false
var _over := false
var _easy := false
var _msg := ""
var _gate_state: Array = []     # "", "ok" or "miss" per gate
var _wake: Array = []           # recent positions, for the wake
var _wake_t := 0.0
var _floaters: Array = []
var _stroke_anim := {"l": 0.0, "r": 0.0}
var _anim := 0.0
var _trees: Array = []
var _reeds: Array = []
var _crowd: Array = []
var _stage: Control
var _info: Label
var _last_count := 99

func _build() -> void:
	set_title("Coracle racing")
	_easy = Settings.easy_darts
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = STAGE
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["move_left", "Paddle left"], ["move_right", "Paddle right"], ["confirm", "Brace"], ["cancel", "Climb out"]])
	_load(_venue_id)

func setup(arg: String) -> void:
	_venue_id = arg if not Coracle.venue(arg).is_empty() else "ironbridge"
	_load(_venue_id)
	if arg == "dev_end":   # one stride from the line, to try the finish and the party piece prompt
		_s.p = Vector2(Coracle.finish_x(_course) - 0.2, Coracle.centre(_course, Coracle.finish_x(_course) - 0.2))
		_s.v = Vector2(3.0, 0.0)
		_s.gate = _gates.size()
		_s.t = 27.5
		_clock = 27.5
		_started = true
	elif arg.begins_with("dev"):   # four gates through, a little spin on
		_s.p = Vector2(52.0, Coracle.centre(_course, 52.0) + 2.5)
		_s.v = Vector2(2.0, 0.4)
		_s.h = 0.35
		_s.spin = 0.9
		_s.t = 16.0
		_s.gate = 4
		_s.hits = 3
		_s.misses = 1
		_gate_state = ["ok", "ok", "miss", "ok", "", "", "", ""]
		for i in 14:
			_wake.append(Vector2(52.0 - float(i) * 0.7, Coracle.centre(_course, 52.0 - float(i) * 0.7) + 2.5 - float(i) * 0.1))
		_clock = 16.0
		_started = true
		_floaters.append({"text": "+3s", "pos": Vector2(OX + 40.0 * PX, OY - 80.0), "t": 0.3, "col": Color("d9604a")})
		_msg = "Gate missed: three seconds on. Alternate your strokes."
	_refresh()

func _load(id: String) -> void:
	_venue = Coracle.venue(id)
	_course = _venue.course
	_rival = _venue.rival
	_gates = Coracle.gates(_course, _easy)
	_s = Coracle.fresh(_course, _rng.roll_int(1, 1 << 20))
	_their_time = Coracle.local_time(_rival, _rng)
	_gate_state = []
	for g in _gates:
		_gate_state.append("")
	_scenery()
	_refresh()

func _scenery() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1781
	_trees.clear()
	_reeds.clear()
	_crowd.clear()
	var half := float(_course.get("width", 22.0)) * 0.5
	for i in 22:
		var x := 2.0 + float(i) * 5.7 + r.randf() * 2.0
		for side in [-1.0, 1.0]:
			if r.randf() < 0.8:
				_trees.append({"p": _px(x, Coracle.centre(_course, x) + side * (half + 2.5 + r.randf() * 5.0)), "r": 18.0 + r.randf() * 14.0, "t": r.randf()})
	for i in 70:
		var x := 1.0 + r.randf() * (Coracle.finish_x(_course) + 3.0)
		var side := -1.0 if r.randf() < 0.5 else 1.0
		_reeds.append(_px(x, Coracle.centre(_course, x) + side * (half - 0.2 + r.randf() * 0.5)))
	var fx := Coracle.finish_x(_course)
	for i in 26:
		var x := fx - 6.0 + r.randf() * 11.0
		var side := -1.0 if i % 2 == 0 else 1.0
		_crowd.append({"p": _px(x, Coracle.centre(_course, x) + side * (half + 0.7 + r.randf() * 2.4)), "col": [Color("c0504d"), Color("4f81bd"), Color("e0c050"), Color("e8e0d0"), Color("b070b0")][r.randi() % 5], "b": r.randf() * TAU})

func _px(x: float, y: float) -> Vector2:
	return Vector2(OX + x * PX, OY + (y - MID_M) * PX)

func _process(delta: float) -> void:
	_anim += delta
	for k in ["l", "r"]:
		_stroke_anim[k] = maxf(0.0, float(_stroke_anim[k]) - delta * 4.0)
	for f in _floaters:
		f.t = float(f.t) + delta
	while not _floaters.is_empty() and float(_floaters[0].t) > 1.2:
		_floaters.pop_front()
	_stage.queue_redraw()
	if _over:
		return
	_clock += delta
	if not _started:
		var n := int(ceil(-_clock))
		if n != _last_count and n > 0:
			_last_count = n
			Audio.sfx_at("cursor", -6.0, 0.8 + 0.2 * float(COUNT - n))
		if _clock >= 0.0:
			_started = true
			Audio.sfx("splash")
			_msg = "Go! Left, right, left, right."
			_refresh()
		return
	if Input.is_action_just_pressed("move_left") and Coracle.paddle(_s, "l"):
		_stroked("l")
	elif Input.is_action_just_pressed("move_right") and Coracle.paddle(_s, "r"):
		_stroked("r")
	if Input.is_action_just_pressed("confirm"):
		Coracle.brace(_s)
		Audio.sfx_at("atk_splash", -6.0, 0.7)
	for e in Coracle.step(_s, _course, _gates, delta, _easy):
		match e:
			"gate":
				_gate_state[int(_s.gate) - 1] = "ok"
				Audio.sfx_at("confirm", -4.0, 1.0 + 0.05 * float(_s.hits))
				_say("Through!", UIKit.GOLD)
			"miss":
				_gate_state[int(_s.gate) - 1] = "miss"
				Audio.sfx("cancel")
				_say("+3s", Color("d9604a"))
				_msg = "Missed a gate: three seconds on."
				_refresh()
			"bump":
				Audio.sfx_at("bump", -4.0)
				_say("Bank!", Color("d98a6a"))
			"finish":
				_finished()
				return
	_wake_t += delta
	if _wake_t > 0.07:
		_wake_t = 0.0
		_wake.append(Vector2(_s.p))
		if _wake.size() > 26:
			_wake.pop_front()
	if absf(float(_s.spin)) > 2.4 and fposmod(_clock, 1.0) < delta:
		_say("Spinning!", Color("e8a030"))
		Audio.sfx_at("scramble", -10.0)

func _stroked(side: String) -> void:
	_stroke_anim[side] = 1.0
	Audio.sfx_at("atk_splash", -9.0, 1.25 if side == "l" else 1.1)

func _say(text: String, col: Color) -> void:
	var p := _px(float(_s.p.x), float(_s.p.y))
	_floaters.append({"text": text, "pos": p + Vector2(-20, -34), "t": 0.0, "col": col})
	if _floaters.size() > 5:
		_floaters.pop_front()

func _finished() -> void:
	_over = true
	var mine := Coracle.score(_s)
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var won := mine < _their_time
	Audio.sfx("level_up" if won else "cancel")
	var pen := " (%d missed, +%ds)" % [int(_s.misses), int(Coracle.MISS_PENALTY) * int(_s.misses)] if int(_s.misses) > 0 else ""
	_msg = "%.1fs%s. %s: %.1fs.%s" % [mine, pen, who, _their_time, _verdict(mine, _their_time, won)]
	_refresh()
	await get_tree().create_timer(2.4).timeout
	await PiecePrompt.after_game(self, "coracle", mine)
	close({"won": won, "time": mine})

## The line after the times: a win and by how much, a dead heat when the two read the same, or not this time.
static func _verdict(mine: float, theirs: float, won: bool) -> String:
	if absf(theirs - mine) < 0.05:
		return " A dead heat. You need to beat the time, not match it." if not won else " You win by a whisker."
	return " You win by %.1f seconds." % (theirs - mine) if won else " Not this time."

func _on_cancel() -> void:
	if _over:
		return
	close(null)

func _refresh() -> void:
	if _info == null or _venue.is_empty():
		return
	var who := str(_rival.get("who", "The local")).split(",")[0]
	_info.text = "Against %s.  Gates %d of %d, %d missed.  %s" % [who, int(_s.get("gate", 0)), _gates.size(), int(_s.get("misses", 0)), _msg]

# ---- drawing

func _draw_stage() -> void:
	if _venue.is_empty():
		return
	var c := _stage
	var w := STAGE.x
	var half := float(_course.get("width", 22.0)) * 0.5
	var fx := Coracle.finish_x(_course)
	# grass everywhere, mottled, then the river as a band following the centre line
	c.draw_rect(Rect2(0, 0, w, STAGE.y), Color("5d7a3d"))
	for i in 60:
		var gx := fposmod(float(i) * 211.0, w)
		var gy := fposmod(float(i) * 137.0, STAGE.y)
		c.draw_circle(Vector2(gx, gy), 26.0, Color("668647") if i % 2 == 0 else Color("54703a"))
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var bank_t := PackedVector2Array()
	var bank_b := PackedVector2Array()
	var x := 0.0
	while x <= (w - OX) / PX + 0.01:
		var cy := Coracle.centre(_course, x)
		top.append(_px(x, cy - half))
		bot.append(_px(x, cy + half))
		bank_t.append(_px(x, cy - half - 0.9))
		bank_b.append(_px(x, cy + half + 0.9))
		x += 1.0
	for i in top.size() - 1:
		c.draw_colored_polygon(PackedVector2Array([bank_t[i], bank_t[i + 1], bank_b[i + 1], bank_b[i]]), Color("8a7a52"))
	for i in top.size() - 1:
		c.draw_colored_polygon(PackedVector2Array([top[i], top[i + 1], bot[i + 1], bot[i]]), Color("3f7f8f"))
	# a deeper channel down the middle and current streaks moving downstream
	var mid := PackedVector2Array()
	var xx := 0.0
	while xx <= (w - OX) / PX + 0.01:
		mid.append(_px(xx, Coracle.centre(_course, xx)))
		xx += 1.0
	c.draw_polyline(mid, Color("35707f"), half * PX * 0.9)
	for i in 34:
		var sx := fposmod(float(i) * 83.0 + _anim * 14.0, w - OX)
		var sxm := sx / PX
		var sy := Coracle.centre(_course, sxm) + (fposmod(float(i) * 5.3, half * 1.8) - half * 0.9)
		var sp := _px(sxm, sy)
		c.draw_line(sp, sp + Vector2(16, 0), Color(1, 1, 1, 0.14), 2.0)
	# reeds, lily pads, trees
	for rp in _reeds:
		c.draw_line(rp, rp + Vector2(-2, -12), Color("4d6a2a"), 2.0)
		c.draw_line(rp + Vector2(3, 0), rp + Vector2(5, -10), Color("5e7e32"), 2.0)
		c.draw_circle(rp + Vector2(-2, -13), 2.5, Color("6a4a2a"))
	for tr in _trees:
		var pp: Vector2 = tr.p
		var sway := sin(_anim * 0.8 + float(tr.t) * 6.0) * 1.5
		c.draw_circle(pp + Vector2(4, 6), float(tr.r), Color(0, 0, 0, 0.18))
		c.draw_circle(pp + Vector2(sway, 0), float(tr.r), Color("3f6a34"))
		c.draw_circle(pp + Vector2(sway - 4, -4), float(tr.r) * 0.65, Color("4f7e40"))
	# the finish: the Iron Bridge arch over the water for Ironbridge, a rope and flags otherwise
	var fp_top := _px(fx, Coracle.centre(_course, fx) - half - 1.5)
	var fp_bot := _px(fx, Coracle.centre(_course, fx) + half + 1.5)
	if str(_venue.get("style", "")) == "bridge":
		c.draw_rect(Rect2(fp_top.x - 14, fp_top.y, 28, fp_bot.y - fp_top.y), Color(0, 0, 0, 0.18))
		c.draw_rect(Rect2(fp_top.x - 10, fp_top.y, 20, fp_bot.y - fp_top.y), Color("6f5a52"))
		c.draw_line(Vector2(fp_top.x - 10, fp_top.y), Vector2(fp_top.x - 10, fp_bot.y), Color("2f2a2a"), 3.0)
		c.draw_line(Vector2(fp_top.x + 10, fp_top.y), Vector2(fp_top.x + 10, fp_bot.y), Color("2f2a2a"), 3.0)
		for k in 9:
			var by := lerpf(fp_top.y, fp_bot.y, float(k) / 8.0)
			c.draw_line(Vector2(fp_top.x - 10, by), Vector2(fp_top.x + 10, by), Color("3a3232"), 2.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(fp_bot.x - 130, fp_bot.y + 20), "FINISH, 1781", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)
	else:
		c.draw_line(fp_top, fp_bot, Color("f2e8cf"), 4.0)
	for p in _crowd:
		var q: Vector2 = p.p + Vector2(0, sin(_anim * 3.0 + float(p.b)) * 1.5)
		c.draw_circle(q, 5.0, p.col)
		c.draw_circle(q + Vector2(0, -2), 3.0, Color("e8c8a0"))
	# the buoys
	for i in _gates.size():
		_draw_gate(i)
	# the ghost of the local, then your wake, then you
	var gf := clampf(maxf(_clock, 0.0) / _their_time, 0.0, 1.0)
	var gx2 := 4.0 + (fx - 4.0) * gf
	_draw_coracle(_px(gx2, Coracle.centre(_course, gx2) - 2.0 + sin(gx2 * 0.7) * 0.6), 0.0 + cos(gx2 * 0.7) * 0.1, true, 0.0, 0.0)
	for k in _wake.size():
		var a := float(k) / float(maxi(1, _wake.size()))
		c.draw_circle(_px(float(_wake[k].x), float(_wake[k].y)), 3.0 + a * 8.0, Color(1, 1, 1, 0.05 + 0.12 * a))
	_draw_coracle(_px(float(_s.p.x), float(_s.p.y)), float(_s.h), false, float(_stroke_anim.l), float(_stroke_anim.r))
	for f in _floaters:
		var a := clampf(1.0 - float(f.t) / 1.2, 0.0, 1.0)
		var col: Color = f.col
		col.a = a
		_text(f.pos + Vector2(0, -float(f.t) * 26.0), f.text, 30, col, a)
	_draw_hud()

func _draw_gate(i: int) -> void:
	var c := _stage
	var g: Dictionary = _gates[i]
	var a := _px(float(g.x), float(g.y) - float(g.gap) * 0.5)
	var b := _px(float(g.x), float(g.y) + float(g.gap) * 0.5)
	var st: String = _gate_state[i]
	var line := Color(1, 1, 1, 0.25)
	if st == "ok":
		line = Color("8fe0a0")
		line.a = 0.7
	elif st == "miss":
		line = Color("d9604a")
		line.a = 0.7
	elif i == int(_s.get("gate", 0)):
		line = Color(UIKit.GOLD, 0.55 + 0.3 * sin(_anim * 5.0))
	c.draw_line(a, b, line, 2.0)
	for pair in [[a, Color("c0504d")], [b, Color("f2e8cf")]]:
		var p: Vector2 = pair[0]
		var bob := sin(_anim * 2.0 + p.y) * 1.5
		c.draw_circle(p + Vector2(0, bob + 3), 9.0, Color(0, 0, 0, 0.18))
		c.draw_circle(p + Vector2(0, bob), 8.0, pair[1])
		c.draw_circle(p + Vector2(0, bob), 4.0, Color("2a2a30"))
	c.draw_string(ThemeDB.fallback_font, (a + b) * 0.5 + Vector2(-5, 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))

## A coracle from above: a woven round hull with ribs, a bow mark, the paddler and the paddle on the stroked side.
func _draw_coracle(p: Vector2, h: float, ghost: bool, l_anim: float, r_anim: float) -> void:
	var c := _stage
	var a := 0.45 if ghost else 1.0
	c.draw_circle(p + Vector2(3, 5), 17.0, Color(0, 0, 0, 0.2 * a))
	c.draw_set_transform(p, h, Vector2(1.0, 0.86))
	c.draw_circle(Vector2.ZERO, 17.0, (Color("e0b060") if not ghost else Color("e07070")) * Color(1, 1, 1, a))
	c.draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 26, Color("5a3a1c", a), 3.0)
	for k in range(-2, 3):
		c.draw_line(Vector2(-14, float(k) * 5.5), Vector2(14, float(k) * 5.5), Color("a8783a", a * 0.8), 1.5)
		c.draw_line(Vector2(float(k) * 5.5, -14), Vector2(float(k) * 5.5, 14), Color("a8783a", a * 0.6), 1.5)
	c.draw_colored_polygon(PackedVector2Array([Vector2(17, -4), Vector2(23, 0), Vector2(17, 4)]), Color("3a2410", a))   # the bow
	c.draw_set_transform(p, h, Vector2.ONE)
	c.draw_circle(Vector2(-1, 0), 8.0, Color("2f5a8a" if not ghost else "7a3a4a", a))
	c.draw_circle(Vector2(1, 0), 5.0, Color("e8c8a0", a))
	c.draw_rect(Rect2(-3, -5, 8, 3), Color("3a3a50", a))
	for pr in [["l", l_anim, 1.0], ["r", r_anim, -1.0]]:
		var sweep: float = pr[1]
		var side: float = pr[2]
		var base := Vector2(2, side * 8.0)
		var tip := base + Vector2(-26.0 * sweep + 10.0 * (1.0 - sweep), side * (16.0 + 8.0 * sweep))
		if not ghost or sweep > 0.0:
			c.draw_line(base, tip, Color("6a4a2a", a), 3.0)
			c.draw_circle(tip, 4.5, Color("8a6a3a", a))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not ghost and absf(float(_s.get("spin", 0.0))) > 2.4:
		for k in 3:
			var ang := _anim * 6.0 + float(k) * TAU / 3.0
			c.draw_circle(p + Vector2(cos(ang), sin(ang) * 0.5) * 16.0 + Vector2(0, -22), 3.0, Color("e8c872"))

func _draw_hud() -> void:
	var c := _stage
	var font := ThemeDB.fallback_font
	c.draw_rect(Rect2(8, 6, 240, 64), Color(0.05, 0.06, 0.1, 0.6))
	var t := maxf(0.0, float(_s.t)) + Coracle.MISS_PENALTY * float(_s.misses)
	c.draw_string(font, Vector2(20, 44), "%.1fs" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, UIKit.CREAM)
	c.draw_string(font, Vector2(20, 64), "Gate %d of %d" % [mini(int(_s.gate) + 1, _gates.size()), _gates.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.MUTED)
	if int(_s.misses) > 0:
		c.draw_string(font, Vector2(150, 44), "+%ds" % (int(Coracle.MISS_PENALTY) * int(_s.misses)), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("d9604a"))
	# the spin gauge: how fast the boat is turning, which side the next stroke turns it
	var sp := clampf(float(_s.spin) / 3.0, -1.0, 1.0)
	c.draw_rect(Rect2(STAGE.x - 258, STAGE.y - 48, 250, 40), Color(0.05, 0.06, 0.1, 0.6))
	c.draw_string(font, Vector2(STAGE.x - 250, STAGE.y - 32), "Spin", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.MUTED)
	var gx := STAGE.x - 133.0
	c.draw_rect(Rect2(gx - 110, STAGE.y - 28, 220, 12), Color("2c3a52"))
	c.draw_rect(Rect2(gx - 1, STAGE.y - 30, 2, 16), UIKit.CREAM)
	c.draw_rect(Rect2(gx, STAGE.y - 28, sp * 110.0, 12) if sp >= 0.0 else Rect2(gx + sp * 110.0, STAGE.y - 28, -sp * 110.0, 12), Color("e8a030") if absf(sp) > 0.7 else Color("78b6d8"))
	if not _started:
		var n := int(ceil(-_clock))
		_text(Vector2(STAGE.x * 0.5 - 20, STAGE.y * 0.5), str(n) if n > 0 else "Go!", 88, UIKit.GOLD, 1.0)

func _text(pos: Vector2, text: String, size: int, col: Color, a := 1.0) -> void:
	_stage.draw_string_outline(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, a * 0.6))
	_stage.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
