extends MenuBase
## Bog snorkelling (story command {"do": "snorkel"}): two lengths of a peat trench, flippers only. Press Left and
## Right in turn on the beat (the ring shrinks onto the target as the beat lands); steady kicks build speed, ragged
## ones silt up the snorkel. Confirm blows the snorkel clear. Your time against the local's, drawn as two swimmers.
## The numbers live in Snorkel. Closes with {"won": bool, "time": float} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a swim part way through).

const STAGE := Vector2(1184, 410)
const SKY_H := 120.0
const FAR_Y := 168.0          # the far bank's foot
const NEAR_LANE := 262.0      # your lane's centre line
const FAR_LANE := 206.0       # the local's
const TRENCH_Y0 := 172.0
const TRENCH_Y1 := 296.0
const X0 := 70.0
const X1 := 1114.0
const WATER := Color("4a3626")
const WATER_DEEP := Color("33241a")
const PEAT := Color("2a1d15")
const GRASS := Color("5f7a3f")
const GRASS_DK := Color("46602f")
const COUNT_IN := 4           # beats before "go"

var _venue_id := "waen_rhydd"
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _s: Dictionary = Snorkel.fresh(Time.get_ticks_usec() % 1000003 + 1)
var _their_time := 78.0
var _clock := -float(COUNT_IN) * Snorkel.BEAT
var _last_beat := -99
var _started := false
var _over := false
var _easy := false
var _msg := ""
var _flash := {"l": 0.0, "r": 0.0}
var _flash_col := {"l": Color.WHITE, "r": Color.WHITE}
var _floaters: Array = []      # {text, pos, t, col}
var _bubbles: Array = []       # {p: Vector2, t: float}
var _crowd: Array = []         # {x, y, col, hat, h}
var _bunting: Array = []
var _stage: Control
var _info: Label
var _flip_phase := 0.0
var _rival_x := 0.0
var _swallow_t := 0.0

func _build() -> void:
	set_title("Bog snorkelling")
	_easy = Settings.easy_darts
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = STAGE
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["move_left", "Left flipper"], ["move_right", "Right flipper"], ["confirm", "Blow snorkel"], ["cancel", "Climb out"]])
	_rival = Snorkel.venue(_venue_id).rival
	_scenery()
	_start()

func setup(arg: String) -> void:
	_venue_id = arg if not Snorkel.venue(arg).is_empty() else "waen_rhydd"
	_rival = Snorkel.venue(_venue_id).rival
	if arg == "dev_end":    # on the last yard, to try the finish and the party piece prompt
		_s.x = Snorkel.LENGTH * 2.0
		_s.length = 1
		_s.t = 51.0
		_clock = 51.0
		_started = true
		_their_time = 64.0
	elif arg.begins_with("dev"):    # part way along the second length, a little silted
		_s = Snorkel.fresh()
		_s.x = 83.0
		_s.length = 1
		_s.t = 38.0
		_s.breath = 0.55
		_s.silt = 0.5
		_s.streak = 4
		_clock = 38.0
		_started = true
		_last_beat = int(floor(_clock / Snorkel.BEAT))
		_their_time = 70.0
		_msg = "Steady. Keep it alternate."
		_floaters.append({"text": "Good!", "pos": Vector2(700, 232), "t": 0.2, "col": UIKit.GOLD})
		for i in 9:
			_bubbles.append({"p": Vector2(X1 - 60.0 - float(i) * 22.0, NEAR_LANE - 8.0 - float(i % 3) * 7.0), "t": float(i) * 0.1})
	_refresh()

func _start() -> void:
	if not _started:
		_their_time = Snorkel.local_time(_rival, _rng)
	_refresh()

func _scenery() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1535
	var cols := [Color("c0504d"), Color("4f81bd"), Color("e0c050"), Color("7aa65a"), Color("b070b0"), Color("e8e0d0"), Color("d08040")]
	for i in 46:
		_crowd.append({"x": 30.0 + r.randf() * (STAGE.x - 60.0), "y": FAR_Y - 22.0 + r.randf() * 14.0, "col": cols[r.randi() % cols.size()],
			"hat": r.randf() < 0.3, "h": 14.0 + r.randf() * 6.0, "bob": r.randf() * TAU})
	for i in 14:
		_bunting.append(["c0504d", "e8e0d0", "4f81bd", "e0c050", "7aa65a"][i % 5])

func _beat_err() -> float:
	var ph := fposmod(_clock, Snorkel.BEAT)
	return ph if ph < Snorkel.BEAT * 0.5 else ph - Snorkel.BEAT

func _process(delta: float) -> void:
	_flip_phase += delta
	_swallow_t = maxf(0.0, _swallow_t - delta)
	for k in ["l", "r"]:
		_flash[k] = maxf(0.0, float(_flash[k]) - delta * 3.0)
	for f in _floaters:
		f.t = float(f.t) + delta
	while not _floaters.is_empty() and float(_floaters[0].t) > 1.1:
		_floaters.pop_front()
	for b in _bubbles:
		b.t = float(b.t) + delta
		b.p.y -= delta * 26.0
	while not _bubbles.is_empty() and float(_bubbles[0].t) > 1.4:
		_bubbles.pop_front()
	_stage.queue_redraw()
	if _over:
		return
	_clock += delta
	var beat_i := int(floor(_clock / Snorkel.BEAT))
	if beat_i != _last_beat:
		_last_beat = beat_i
		if not _started:
			Audio.sfx_at("cursor", -8.0, 0.8 + 0.15 * float(COUNT_IN + beat_i))
		elif not bool(_s.done):
			Audio.sfx_at("cursor", -16.0, 0.6)
	if not _started:
		if _clock >= 0.0:
			_started = true
			_msg = "Go! Left, right, left, right."
			Audio.sfx("splash")
			_refresh()
		return
	var v := _beat_err()
	if Input.is_action_just_pressed("move_left"):
		_kick("l", v)
	elif Input.is_action_just_pressed("move_right"):
		_kick("r", v)
	if Input.is_action_just_pressed("confirm") and Snorkel.blow(_s):
		Audio.sfx("atk_whoosh")
		_say("Phoo!", UIKit.CREAM)
		_msg = "Snorkel clear."
		_refresh()
	for e in Snorkel.tick(_s, delta):
		match e:
			"turn":
				Audio.sfx("splash")
				_say("Turn!", UIKit.GOLD)
				_msg = "Turn at the wall, and back."
			"swallow":
				Audio.sfx("bog_squelch")
				Audio.sfx("stat_down")
				_swallow_t = 2.2
				_say("Glug.", Color("d98a6a"))
				_msg = "Out of breath. You swallowed a bit of Wales."
			"finish":
				_finished()
				return

func _kick(side: String, err: float) -> void:
	var g := Snorkel.kick(_s, side, err, _easy)
	if g == "":
		return
	_flash[side] = 1.0
	var col: Color = {"good": UIKit.GOLD, "ok": UIKit.CREAM, "ragged": Color("d9604a")}[g]
	_flash_col[side] = col
	match g:
		"good":
			Audio.sfx_at("step_wet", -2.0, 1.0 + 0.04 * float(_s.streak))
			_say("Good!" if int(_s.streak) < 3 else "Rhythm x%d" % int(_s.streak), col)
		"ok":
			Audio.sfx_at("step_wet", -6.0, 0.85)
		_:
			Audio.sfx_at("bog_squelch", -4.0)
			_say("Ragged", col)
	for i in 2:
		_bubbles.append({"p": _swimmer_pos() + Vector2(randf_range(-30, 0), randf_range(-12, 6)), "t": 0.0})
	if _bubbles.size() > 24:
		_bubbles.pop_front()

func _say(text: String, col: Color) -> void:
	_floaters.append({"text": text, "pos": _swimmer_pos() + Vector2(-20, -60), "t": 0.0, "col": col})
	if _floaters.size() > 5:
		_floaters.pop_front()

func _finished() -> void:
	_over = true
	var mine := float(_s.t)
	var who := str(_rival.get("who", "The champion")).split(",")[0]
	var won := mine < _their_time
	Audio.sfx("level_up" if won else "cancel")
	_msg = "%s. %s: %s.%s" % [Snorkel.fmt(mine), who, Snorkel.fmt(_their_time), _verdict(mine, _their_time, won)]
	_refresh()
	await get_tree().create_timer(2.4).timeout
	await PiecePrompt.after_game(self, "snorkel", mine)
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
	if _info == null:
		return
	var who := str(_rival.get("who", "The champion")).split(",")[0]
	_info.text = "Against %s (%s).  %s" % [who, Snorkel.fmt(_their_time) if _over else "time unseen", _msg]

# ---- drawing

func _yd_to_x(yd: float) -> float:
	return lerpf(X0, X1, yd / Snorkel.LENGTH)

func _swimmer_pos() -> Vector2:
	return Vector2(_yd_to_x(Snorkel.lane_x(_s)), NEAR_LANE)

func _rival_pos() -> Vector2:
	var frac := clampf(maxf(_clock, 0.0) / _their_time, 0.0, 1.0)
	var yd := frac * Snorkel.LENGTH * 2.0
	var lane := Snorkel.LENGTH - (yd - Snorkel.LENGTH) if yd > Snorkel.LENGTH else yd
	return Vector2(_yd_to_x(lane), FAR_LANE)

func _facing() -> float:
	return -1.0 if int(_s.length) % 2 == 1 else 1.0

func _draw_stage() -> void:
	var w := STAGE.x
	var c := _stage
	# sky and the Epynt hills behind
	for i in 12:
		c.draw_rect(Rect2(0, float(i) * SKY_H / 12.0, w, SKY_H / 12.0 + 1.0), Color("9cc4d6").lerp(Color("e9dfc4"), float(i) / 11.0))
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, 118), Vector2(0, 76), Vector2(120, 52), Vector2(260, 74), Vector2(400, 40), Vector2(560, 70), Vector2(700, 46), Vector2(860, 78), Vector2(1000, 54), Vector2(w, 72), Vector2(w, 118)]), Color("7d9a86"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, 118), Vector2(0, 96), Vector2(180, 84), Vector2(340, 100), Vector2(520, 88), Vector2(760, 102), Vector2(940, 90), Vector2(w, 100), Vector2(w, 118)]), Color("668a63"))
	# a marquee with a flag, bunting along the far bank
	c.draw_rect(Rect2(880, 70, 130, 54), Color("efe6d0"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(870, 72), Vector2(945, 34), Vector2(1020, 72)]), Color("c0504d"))
	c.draw_line(Vector2(945, 34), Vector2(945, 14), Color("5a4a3a"), 2.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(945, 14), Vector2(968, 20), Vector2(945, 26)]), Color("e8c872"))
	# far bank, the crowd and bunting
	c.draw_rect(Rect2(0, 112, w, FAR_Y - 112.0 + 6.0), GRASS)
	c.draw_rect(Rect2(0, 112, w, 6), GRASS_DK)
	for p in _crowd:
		var bob := sin(_flip_phase * 3.0 + float(p.bob)) * 1.5
		var x: float = p.x
		var y: float = float(p.y) + bob
		c.draw_rect(Rect2(x - 5, y, 10, float(p.h)), p.col)
		c.draw_circle(Vector2(x, y - 5), 5.5, Color("e8c8a0"))
		if bool(p.hat):
			c.draw_rect(Rect2(x - 7, y - 11, 14, 4), Color("3a3a50"))
	c.draw_line(Vector2(20, 116), Vector2(w - 20, 116), Color("5a4a3a"), 2.0)
	var n := _bunting.size()
	for i in n:
		var x0 := 20.0 + (w - 40.0) * float(i) / float(n)
		var x1 := 20.0 + (w - 40.0) * float(i + 1) / float(n)
		var sag := 6.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x0 + 3, 117), Vector2(x1 - 3, 117), Vector2((x0 + x1) * 0.5, 117.0 + sag + 6.0)]), Color(str(_bunting[i])))
	c.draw_rect(Rect2(0, FAR_Y, w, TRENCH_Y0 - FAR_Y), Color("7c5c3a"))   # the peat lip
	# the trench: peat water in bands, with floating weed
	c.draw_rect(Rect2(0, TRENCH_Y0, w, TRENCH_Y1 - TRENCH_Y0), WATER)
	c.draw_rect(Rect2(0, TRENCH_Y0 + 6, w, 22), WATER_DEEP.lerp(WATER, 0.5))
	c.draw_rect(Rect2(0, TRENCH_Y1 - 26, w, 20), WATER_DEEP)
	for i in 18:
		var rx := fposmod(float(i) * 97.0 + _flip_phase * 6.0, w)
		c.draw_line(Vector2(rx, TRENCH_Y0 + 10 + float((i * 37) % 100)), Vector2(rx + 22, TRENCH_Y0 + 10 + float((i * 37) % 100)), Color(1, 0.9, 0.7, 0.08), 2.0)
	c.draw_rect(Rect2(0, TRENCH_Y1, w, 8), PEAT)
	# the near bank: boardwalk, yard tapes
	c.draw_rect(Rect2(0, TRENCH_Y1 + 8.0, w, 34), Color("8a6a46"))
	for i in 40:
		c.draw_line(Vector2(float(i) * 30.0, TRENCH_Y1 + 8.0), Vector2(float(i) * 30.0, TRENCH_Y1 + 42.0), Color("6a4e32"), 2.0)
	for k in 5:
		var tx := _yd_to_x(float(k) * 15.0)
		c.draw_line(Vector2(tx, TRENCH_Y0), Vector2(tx, TRENCH_Y1), Color(1, 1, 1, 0.22), 2.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(tx - 12, TRENCH_Y1 + 28), "%d" % (k * 15), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2e8cf"))
	c.draw_string(ThemeDB.fallback_font, Vector2(X0 - 56, TRENCH_Y1 + 28), "yards", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8d8b0"))
	# end walls with the start/finish board
	c.draw_rect(Rect2(0, TRENCH_Y0, 38, TRENCH_Y1 - TRENCH_Y0), PEAT)
	c.draw_rect(Rect2(w - 38, TRENCH_Y0, 38, TRENCH_Y1 - TRENCH_Y0), PEAT)
	# silt cloud behind you
	var me := _swimmer_pos()
	var silt := float(_s.silt)
	if silt > 0.05:
		for i in 5:
			c.draw_circle(me + Vector2(-_facing() * (30.0 + float(i) * 16.0), sin(_flip_phase * 3.0 + float(i)) * 6.0), 12.0 + 4.0 * float(i), Color(0.36, 0.26, 0.17, 0.22 * silt + 0.05))
	for b in _bubbles:
		var a := clampf(1.0 - float(b.t) / 1.4, 0.0, 1.0)
		c.draw_arc(b.p, 3.0 + float(b.t) * 2.0, 0.0, TAU, 8, Color(0.85, 0.95, 1.0, a * 0.8), 1.5)
	_draw_swimmer(_rival_pos(), 1.0 if _rival_dir() else -1.0, Color("c0504d"), 0.0, true)
	_draw_swimmer(me, _facing(), Color("2f6f8f"), float(_flash.l) - float(_flash.r), false)
	for f in _floaters:
		var a := clampf(1.0 - float(f.t) / 1.1, 0.0, 1.0)
		var col: Color = f.col
		col.a = a
		_text(f.pos + Vector2(0, -float(f.t) * 30.0), f.text, 30, col, a)
	_draw_hud()

func _rival_dir() -> bool:
	return maxf(_clock, 0.0) / _their_time * 2.0 < 1.0

## A swimmer seen from the boardwalk: body, mask and snorkel, and two flippers that kick in turn.
func _draw_swimmer(p: Vector2, dir: float, suit: Color, kick: float, rival: bool) -> void:
	var c := _stage
	var f := dir
	var wobble := sin(_flip_phase * 9.0) * 3.0 if (rival or float(_s.pause) <= 0.0) and _started else 0.0
	c.draw_circle(p + Vector2(0, 12), 22.0, Color(0, 0, 0, 0.18))
	# flippers (behind the body): alternate up and down; the kicked one swings wide
	var fl_up := 8.0 + (kick * 10.0 if not rival else wobble * 2.0)
	var fl_dn := 8.0 - (kick * 10.0 if not rival else wobble * 2.0)
	c.draw_line(p + Vector2(-24 * f, -3), p + Vector2(-50 * f, -fl_up - 2), Color("e8a030"), 8.0)
	c.draw_line(p + Vector2(-24 * f, 3), p + Vector2(-50 * f, fl_dn + 0), Color("d0701c"), 8.0)
	# body and arms trailing back
	c.draw_circle(p + Vector2(-8 * f, 0), 13.0, suit)
	c.draw_circle(p + Vector2(-20 * f, 0), 10.0, suit.darkened(0.15))
	# head, hood, mask
	c.draw_circle(p + Vector2(14 * f, 0), 11.0, suit.lightened(0.1))
	c.draw_circle(p + Vector2(20 * f, 0), 7.0, Color("1a1a24"))
	c.draw_circle(p + Vector2(21 * f, 0), 4.0, Color("9fd4e8"))
	# snorkel: a tube from the mouth up and out, with a bobble on top (fancy dress is encouraged)
	c.draw_line(p + Vector2(12 * f, -7), p + Vector2(8 * f, -26 + wobble * 0.3), Color("e8d040"), 3.0)
	c.draw_circle(p + Vector2(8 * f, -29 + wobble * 0.3), 4.5, Color("d9604a") if not rival else Color("f2e8cf"))
	if float(_swallow_t) > 0.0 and not rival:
		c.draw_string(ThemeDB.fallback_font, p + Vector2(-10, -44), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("d98a6a"))

func _draw_hud() -> void:
	var c := _stage
	var font := ThemeDB.fallback_font
	# clock and length, top right on the sky
	var t := maxf(0.0, float(_s.t))
	c.draw_rect(Rect2(STAGE.x - 258, 4, 250, 66), Color(0.05, 0.06, 0.1, 0.55))
	c.draw_string(font, Vector2(STAGE.x - 246, 40), Snorkel.fmt(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, UIKit.CREAM)
	c.draw_string(font, Vector2(STAGE.x - 246, 62), "Length %d of %d" % [mini(int(_s.length) + 1, Snorkel.LENGTHS), Snorkel.LENGTHS], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.MUTED)
	# breath and snorkel meters, top left
	c.draw_rect(Rect2(8, 4, 330, 66), Color(0.05, 0.06, 0.1, 0.55))
	_meter(Rect2(104, 12, 224, 18), float(_s.breath), Color("78b6d8") if float(_s.breath) > 0.3 else Color("d9604a"), "Breath")
	_meter(Rect2(104, 42, 224, 18), 1.0 - float(_s.silt), Color("8a9a50") if float(_s.silt) < 0.5 else Color("a0704a"), "Snorkel")
	# the rhythm strip along the bottom
	var y := 346.0
	c.draw_rect(Rect2(0, y - 6, STAGE.x, STAGE.y - y + 6), Color(0.05, 0.06, 0.1, 0.78))
	var cx := STAGE.x * 0.5
	var next := "r" if str(_s.last) == "l" else "l"
	for side in ["l", "r"]:
		var px := cx + (-150.0 if side == "l" else 150.0)
		var fl := float(_flash[side])
		var base := Color("2c3a52")
		if side == next and _started and not _over:
			base = Color("3f5578")
		c.draw_rect(Rect2(px - 62, y + 6, 124, 46), base.lerp(_flash_col[side], fl * 0.8), true)
		c.draw_rect(Rect2(px - 62, y + 6, 124, 46), Color(UIKit.HEATHER, 0.6), false, 2.0)
		c.draw_string(font, Vector2(px - 44, y + 40), "Left" if side == "l" else "Right", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIKit.CREAM)
	# the beat ring closes on the target ring as the beat lands
	var ph := fposmod(_clock, Snorkel.BEAT) / Snorkel.BEAT
	var r_out := lerpf(46.0, 20.0, ph)
	var cc := Vector2(cx, y + 30.0)
	var win := Snorkel.window(_easy) / Snorkel.BEAT
	c.draw_arc(cc, 20.0, 0.0, TAU, 28, Color(UIKit.GOLD, 0.9), 3.0)
	if _clock < 0.0:
		var left := int(ceil(-_clock / Snorkel.BEAT))
		c.draw_string(font, cc + Vector2(-9, 11), str(left), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UIKit.GOLD)
	else:
		var near := ph < win or ph > 1.0 - win
		c.draw_arc(cc, r_out, 0.0, TAU, 28, Color("8fe0a0") if near else Color(UIKit.CREAM, 0.7), 4.0 if near else 2.5)
	if _easy:
		c.draw_arc(cc, 20.0, 0.0, TAU, 28, Color(UIKit.GOLD, 0.25), 12.0)

func _text(pos: Vector2, text: String, size: int, col: Color, a := 1.0) -> void:
	_stage.draw_string_outline(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, a * 0.6))
	_stage.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _meter(r: Rect2, frac: float, col: Color, label: String) -> void:
	var c := _stage
	c.draw_string(ThemeDB.fallback_font, Vector2(r.position.x - 92, r.position.y + 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.CREAM)
	c.draw_rect(r, Color("2c3a52"))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)
	c.draw_rect(r, Color(UIKit.HEATHER, 0.6), false, 2.0)
