extends MenuBase
## Welly wanging (story command {"do": "wang"}): Upperthong, West Yorkshire. HOLD Confirm to spin the boot round your
## head (it speeds up the longer you hold; too fast and you go dizzy and wild), and LET GO as it passes the marked gap
## in the swing, about forty degrees up. Mind the flag: a tail wind helps, a head wind does not. Three wangs, the
## furthest counts. Easier minigames widens the gap and nudges your release towards it. The numbers live in WellyWang.
## Closes with {"won": bool, "draw": bool, "best": float} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a spin about to be released and a throw landed).

const STAGE := Vector2(1040, 360)
const GROUND := 300.0
const RADIUS := 56.0
const METRES := 48.0
const FLIGHT := 1.5

var _venue_id := "upperthong"
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _phase := "idle"        # idle, spin, flight, landed, over
var _spin := 0.0
var _swing := 0.0
var _wind := 0.0
var _throws := 0
var _best := 0.0
var _marks: Array = []      # metres of each landed boot, for the flags in the field
var _res: Dictionary = {}
var _t := 0.0
var _wait := 0.4
var _their := -1.0
var _clock := 0.0
var _easy := false
var _dev := false
var _msg := "Hold Confirm to spin. Let go in the bright gap."
var _stage: Control
var _info: Label

func _build() -> void:
	set_title("Welly wanging")
	_easy = Settings.easy_darts
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = STAGE
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Hold to spin, release to wang"], ["cancel", "Walk away"]])
	_rival = WellyWang.venue(_venue_id).rival
	_wind = WellyWang.wind(_rng)
	_refresh()

func setup(arg: String) -> void:
	_venue_id = arg if not WellyWang.venue(arg).is_empty() else "upperthong"
	_rival = WellyWang.venue(_venue_id).rival
	if arg.begins_with("dev"):
		_dev = true
		_throws = 1
		_best = 21.4
		_marks = [21.4]
		_wind = 3.5
		_spin = 0.7
		_swing = 30.0
		_phase = "spin"
		_msg = "Bit of tail wind. Let go in the gap."
	_refresh()

func _on_cancel() -> void:
	if _phase == "over" or _phase == "flight":
		return
	close(null)

func _process(delta: float) -> void:
	_clock += delta
	match _phase:
		"idle":
			_wait = maxf(0.0, _wait - delta)
			if _wait <= 0.0 and Input.is_action_just_pressed("confirm"):
				_phase = "spin"
				_spin = 0.0
				_swing = 0.0
				_msg = "Spinning up. Let go in the bright gap."
				Audio.sfx_at("snare_wobble", -6.0, 0.8)
				_refresh()
		"spin":
			_spin = minf(1.0, _spin + WellyWang.SPIN_RATE * delta)
			_swing = fposmod(_swing + (110.0 + 130.0 * _spin) * delta, 360.0)
			if _spin > WellyWang.DIZZY_ABOVE and fmod(_clock, 0.5) < delta:
				Audio.sfx_at("snare_wobble", -4.0, 1.4)
			if not _dev and not Input.is_action_pressed("confirm"):
				_release()
		"flight":
			_t += delta
			if _t >= FLIGHT:
				_land()
		"landed":
			_wait -= delta
			if _wait <= 0.0:
				_next()
	_stage.queue_redraw()

func _release() -> void:
	if _spin < 0.12:
		_phase = "idle"
		_msg = "You need to spin it up first. Hold Confirm."
		_wait = 0.3
		_refresh()
		return
	var jitter := (_rng.roll() - 0.5) * 60.0
	_res = WellyWang.wang(_spin, WellyWang.assist(_swing, _easy), _wind, jitter)
	_phase = "flight"
	_t = 0.0
	Audio.sfx("throw")
	_refresh()

func _land() -> void:
	_throws += 1
	var m: float = _res.metres
	_marks.append(m)
	var improved := m > _best
	_best = maxf(_best, m)
	_phase = "landed"
	_wait = 1.4
	if bool(_res.foul):
		Audio.sfx("cancel")
		_msg = WellyWang.advice(_res, _spin)
	else:
		Audio.sfx("bump")
		if improved and _throws > 1:
			Audio.sfx("stat_up")
		_msg = "%.1f metres. %s" % [m, WellyWang.advice(_res, _spin)]
	_refresh()

func _next() -> void:
	if _throws >= WellyWang.THROWS:
		_finish()
		return
	_phase = "idle"
	_spin = 0.0
	_wind = WellyWang.wind(_rng)
	_wait = 0.3
	_msg = "Wang %d of %d. %s." % [_throws + 1, WellyWang.THROWS, WellyWang.wind_label(_wind)]
	_refresh()

func _finish() -> void:
	_phase = "over"
	_their = WellyWang.local_best(_rival, _rng)
	var who := str(_rival.get("who", "The champion")).split(",")[0]
	_msg = "Your best: %.1f m. %s wangs %.1f m." % [_best, who, _their]
	_refresh()
	await get_tree().create_timer(2.4).timeout
	await PiecePrompt.after_game(self, WellyWang.GAME_ID, snappedf(_best, 0.1))
	close({"won": _best > _their, "draw": is_equal_approx(_best, _their), "best": snappedf(_best, 0.1)})

func _refresh() -> void:
	if _info == null:
		return
	var who := str(_rival.get("who", "The champion")).split(",")[0]
	_info.text = "Wang %d of %d.   Best: %.1f m.   Against %s.\n%s    %s" % [mini(_throws + 1, WellyWang.THROWS), WellyWang.THROWS, _best, who, WellyWang.wind_label(_wind), _msg]
	_stage.queue_redraw()

# ---- drawing

func _px(m: float) -> float:
	return 190.0 + m / METRES * (STAGE.x - 230.0)

func _draw_stage() -> void:
	var s := _stage
	var w := STAGE.x
	var h := STAGE.y
	var bands := [Color("b7d2e6"), Color("a6c6de"), Color("c3d9e6"), Color("dbe6e8")]
	for i in bands.size():
		s.draw_rect(Rect2(0, i * 52.0, w, 54.0), bands[i])
	# clouds sliding with the wind
	for k in 4:
		var cx := fposmod(120.0 + k * 300.0 + _clock * _wind * 6.0, w + 200.0) - 100.0
		var cy := 40.0 + (k % 2) * 36.0
		for j in 3:
			s.draw_circle(Vector2(cx + j * 26.0, cy + (j % 2) * 6.0), 22.0 - j * 3.0, Color(1, 1, 1, 0.85))
	# the moor: heather bands and a drystone wall
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, 230), Vector2(150, 170), Vector2(330, 205), Vector2(520, 150), Vector2(720, 200), Vector2(900, 160), Vector2(w, 205), Vector2(w, GROUND), Vector2(0, GROUND)]), Color("7a6e9a"))
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, 260), Vector2(220, 225), Vector2(420, 252), Vector2(640, 220), Vector2(860, 250), Vector2(w, 232), Vector2(w, GROUND), Vector2(0, GROUND)]), Color("5f7a4e"))
	s.draw_rect(Rect2(0, 262, w, 38), Color("7a6a50"))
	for k in 40:
		var wx := k * 27.0
		s.draw_rect(Rect2(wx, 264 + (k % 3) * 2, 25, 14), Color("8a7a60").darkened(0.06 * (k % 4)))
		s.draw_rect(Rect2(wx + 12, 278 + (k % 2) * 2, 24, 12), Color("968668").darkened(0.05 * ((k + 1) % 4)))
	s.draw_rect(Rect2(0, GROUND, w, h - GROUND), Color("5a8a3e"))
	s.draw_rect(Rect2(0, GROUND, w, 6), Color("78a85a"))
	for k in 30:
		s.draw_line(Vector2(k * 37.0 + 9, GROUND + 20), Vector2(k * 37.0 + 5, GROUND + 12), Color("78a85a"), 2.0)
	# the tea tent, bunting and the crowd behind the wall
	s.draw_rect(Rect2(w - 170, 196, 120, 68), Color("f0e6d0"))
	s.draw_colored_polygon(PackedVector2Array([Vector2(w - 180, 198), Vector2(w - 110, 160), Vector2(w - 40, 198)]), Color("c9514b"))
	s.draw_string(ThemeDB.fallback_font, Vector2(w - 146, 240), "TEAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("7a2a2a"))
	for k in 9:
		var bx := 40.0 + k * 62.0
		s.draw_colored_polygon(PackedVector2Array([Vector2(bx, 238), Vector2(bx + 24, 238), Vector2(bx + 12, 258)]), [Color("d95f4a"), Color("e8c872"), Color("5fa3c4")][k % 3])
	s.draw_line(Vector2(0, 238), Vector2(w, 238), Color("3a2c28"), 2.0)
	for k in 8:
		var sx := 330.0 + k * 74.0
		s.draw_rect(Rect2(sx - 14, GROUND - 40 + (k % 2) * 3, 28, 30), [Color("2d3347"), Color("4a2d3a"), Color("574a2d"), Color("2d4a3f")][k % 4])
		s.draw_circle(Vector2(sx, GROUND - 48 + (k % 2) * 3), 11.0, Color("e3b48c").darkened(0.1 * (k % 3)))
	# distance marks every 10 metres
	for m in range(10, int(METRES) + 1, 10):
		var x := _px(float(m))
		s.draw_line(Vector2(x, GROUND + 4), Vector2(x, h - 4), Color(1, 1, 1, 0.55), 2.0)
		s.draw_string(ThemeDB.fallback_font, Vector2(x + 6, GROUND + 30), "%dm" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2f2e0"))
	for m in _marks:
		_draw_boot_flag(float(m))
	_draw_wind_flag()
	_draw_thrower()
	_draw_flight()
	if _phase == "landed" or _phase == "over":
		var txt: String = "FOUL" if bool(_res.get("foul", false)) and _phase == "landed" else ("%.1f m" % float(_marks.back()) if not _marks.is_empty() else "")
		s.draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 60, 90), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, UIKit.GOLD if txt != "FOUL" else Color("d9604a"))
	# spin gauge
	s.draw_rect(Rect2(24, 30, 22, 150), Color(0, 0, 0, 0.4))
	s.draw_rect(Rect2(24, 30 + 150 * (1.0 - WellyWang.DIZZY_ABOVE) * 0.0, 22, 150 * (1.0 - WellyWang.DIZZY_ABOVE)), Color("b84a3a"))
	var fillh := 150.0 * _spin
	s.draw_rect(Rect2(26, 180 - fillh, 18, fillh), UIKit.GOLD if _spin <= WellyWang.DIZZY_ABOVE else Color("e8603a"))
	s.draw_string(ThemeDB.fallback_font, Vector2(14, 204), "SPIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)

func _draw_boot_flag(m: float) -> void:
	var x := _px(m)
	_stage.draw_line(Vector2(x, GROUND + 2), Vector2(x, GROUND + 40), Color("e8d8b0"), 3.0)
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(x, GROUND + 4), Vector2(x + 30, GROUND + 12), Vector2(x, GROUND + 20)]), Color("c9514b"))
	_stage.draw_string(ThemeDB.fallback_font, Vector2(x - 20, GROUND + 56), "%.0f" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)

func _draw_wind_flag() -> void:
	var s := _stage
	var p := Vector2(_px(0.0) + 60, 208.0)
	s.draw_line(p, p + Vector2(0, -80), Color("3a2c28"), 4.0)
	var len := 14.0 + absf(_wind) * 7.0
	var dir := 1.0 if _wind >= 0.0 else -1.0
	var wob := sin(_clock * 8.0) * 3.0
	var pts := PackedVector2Array([p + Vector2(0, -80), p + Vector2(dir * len, -76 + wob), p + Vector2(dir * len * 0.95, -62 + wob), p + Vector2(0, -62)])
	s.draw_colored_polygon(pts, Color("e8c872") if absf(_wind) >= 0.75 else Color("c9c0b0"))
	s.draw_string(ThemeDB.fallback_font, p + Vector2(-20, 22), "wind", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIKit.CREAM)

func _hub() -> Vector2:
	return Vector2(112.0, GROUND - 96.0)

func _draw_thrower() -> void:
	var s := _stage
	var c := _hub()
	var bob := sin(_clock * 3.0) * 1.5
	s.draw_rect(Rect2(c.x - 18, c.y + 16, 36, 56), Color("3a5a7a"))        # jumper
	s.draw_rect(Rect2(c.x - 16, c.y + 70, 14, 26), Color("2a2a38"))
	s.draw_rect(Rect2(c.x + 2, c.y + 70, 14, 26), Color("2a2a38"))
	s.draw_circle(c + Vector2(0, bob), 17.0, Color("e3b48c"))
	s.draw_rect(Rect2(c.x - 18, c.y - 18 + bob, 36, 9), Color("5a4a3a"))   # flat cap
	s.draw_rect(Rect2(c.x - 4, c.y - 22 + bob, 24, 6), Color("5a4a3a"))
	if _phase == "spin" or _phase == "idle" and _spin > 0.0:
		# the gap in the swing: bright sector round IDEAL, wider with Easier minigames
		var wnd := WellyWang.WINDOW * (1.6 if _easy else 1.0)
		var a0 := -deg_to_rad(WellyWang.IDEAL + wnd)
		var a1 := -deg_to_rad(WellyWang.IDEAL - wnd)
		_stage.draw_arc(c, RADIUS + 20.0, a0, a1, 12, Color("f4e08a"), 14.0)
		_stage.draw_arc(c, RADIUS + 20.0, -PI * 0.5, 0.0, 24, Color(1, 1, 1, 0.18), 3.0)
	if _phase == "spin":
		var ang := deg_to_rad(_swing)
		var bp := c + Vector2(cos(ang), -sin(ang)) * RADIUS
		s.draw_line(c, bp, Color("e3b48c"), 6.0)
		_draw_boot(bp, -ang + PI * 0.5, 1.0)
		if _spin > WellyWang.DIZZY_ABOVE:
			for k in 3:
				var sa := _clock * 6.0 + k * TAU / 3.0
				s.draw_string(ThemeDB.fallback_font, c + Vector2(cos(sa) * 22 - 6, -30 + sin(sa) * 6), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.GOLD)
	elif _phase == "idle" or _phase == "landed":
		s.draw_line(c, c + Vector2(24, 18), Color("e3b48c"), 6.0)
		_draw_boot(c + Vector2(28, 26), 0.2, 1.0)

func _draw_boot(p: Vector2, rot: float, sc: float) -> void:
	var t := Transform2D(rot, p)
	var pts := PackedVector2Array([Vector2(-5, -14), Vector2(7, -14), Vector2(7, 2), Vector2(18, 6), Vector2(18, 14), Vector2(-5, 14)])
	var out := PackedVector2Array()
	for q in pts:
		out.append(t * (q * sc))
	_stage.draw_colored_polygon(out, Color("3f7a3a"))
	_stage.draw_polyline(out, Color("1f3a1c"), 2.0)
	_stage.draw_line(t * Vector2(-5, 8) * sc, t * Vector2(18, 8) * sc, Color("1f3a1c"), 2.0)

func _draw_flight() -> void:
	if _phase != "flight" and _phase != "landed":
		return
	var m: float = _res.metres
	var f := clampf(_t / FLIGHT, 0.0, 1.0) if _phase == "flight" else 1.0
	var start := _hub() + Vector2(30, 0)
	var land := Vector2(_px(m), GROUND + 4)
	var el: float = clampf(deg_to_rad(maxf(WellyWang.IDEAL * float(_res.quality) * 0.6 + 10.0, 14.0)), 0.2, 1.2)
	var peak := clampf((land.x - start.x) * 0.28 + 16.0, 20.0, 190.0) * (0.4 if bool(_res.foul) else 1.0)
	var pts := PackedVector2Array()
	for k in 21:
		var u := float(k) / 20.0 * f
		var p := start.lerp(land, u)
		p.y = lerpf(start.y, land.y, u) - sin(u * PI) * peak
		if bool(_res.foul):
			p.x = lerpf(start.x, start.x - 80.0, u)
			p.y = lerpf(start.y, land.y, u * u) - sin(u * PI) * 60.0
		pts.append(p)
	if pts.size() > 1:
		_stage.draw_polyline(pts, Color(1, 1, 1, 0.5), 2.0)
	_draw_boot(pts[pts.size() - 1], f * 14.0, 1.1)
