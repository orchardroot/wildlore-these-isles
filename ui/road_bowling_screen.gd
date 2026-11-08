extends MenuBase
## Irish road bowling (story command {"do": "road_bowl"}): a top-down country lane scrolling past. Up and down set the
## power, left and right the swing (the bowl curves as it goes), Run lofts the next throw over the first half of its
## flight, Confirm throws. You and the local throw in turn; fewest throws to the finish line wins. Easier road bowling
## widens the tarmac, steadies the bowl and draws the whole path. The numbers live in RoadBowling. Closes with
## {"won": bool, "draw": bool, "throws": int} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a lofted throw part way round).

const STAGE := Vector2(1184, 330)
const WIN_M := 240.0                     # metres of lane on screen
const POWER_RATE := 0.5                  # fraction per second
const SWING_RATE := 0.9
const PATCH := [Color("5f8f45"), Color("6f9c4c"), Color("557f3d"), Color("7aa655"), Color("688a3f"), Color("86a85a")]
const TARMAC := Color("5d5f66")
const VERGE := Color("7fae52")
const DITCH := Color("3f4a2c")
const HEDGE := Color("2f5a2a")

var _venue_id := "cork"
var _v: Dictionary = {}
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _easy := false
var _me := Vector2.ZERO                  # (s, y) of your bowl on the road
var _them := Vector2.ZERO
var _my_throws := 0
var _their_throws := 0
var _my_done := 0                        # throw number you finished on (0 = not yet)
var _their_done := 0
var _power := 0.7
var _swing := 0.0
var _loft := false
var _anim: Dictionary = {}               # {res, t, dur, who ("me"|"them")}
var _marks: Array = []                   # chalk marks: Vector2 (s, y) of where earlier throws came to rest
var _puffs: Array = []                   # [pos(s,y), age, kind]
var _cam := Vector2(0.0, 0.0)            # (s at the left edge, y at the vertical middle)
var _wait := 0.4
var _over := false
var _msg := "Set the power and the swing, then throw."
var _stage: Control
var _info: Label
var _clock := 0.0

func _build() -> void:
	set_title("Road bowling")
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
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Throw"], ["run", "Loft on/off"], ["cancel", "Walk away"]])
	_load_venue(_venue_id)
	_cam = Vector2(-40.0, RoadBowling.centre(_v, 60.0))
	_refresh()

func _load_venue(id: String) -> void:
	_venue_id = id if not RoadBowling.venue(id).is_empty() else "cork"
	_v = RoadBowling.venue(_venue_id)
	_rival = _v.get("rival", {})

func setup(arg: String) -> void:
	_load_venue(arg if not arg.begins_with("dev") else "cork")
	if arg.begins_with("dev"):
		_me = Vector2(150.0, 6.0)
		_them = Vector2(120.0, 2.0)
		_my_throws = 2
		_their_throws = 2
		_marks = [Vector2(80.0, 0.0), Vector2(150.0, 6.0)]
		_loft = true
		_power = 0.85
		_swing = 0.45
		_msg = "Safe on the tarmac. Next: loft it over the corner."
		_cam = Vector2(110.0, RoadBowling.centre(_v, 220.0))
	_refresh()

func _hw() -> float:
	return RoadBowling.half_width(_v, _easy)

# ---- input and play

func _process(delta: float) -> void:
	_clock += delta
	for p in _puffs:
		p[1] = float(p[1]) + delta
	while not _puffs.is_empty() and float(_puffs[0][1]) > 1.2:
		_puffs.pop_front()
	_follow_camera(delta)
	if _over:
		_stage.queue_redraw()
		return
	if not _anim.is_empty():
		_anim.t = float(_anim.t) + delta
		if float(_anim.t) >= float(_anim.dur):
			_landed()
		_stage.queue_redraw()
		return
	_wait = maxf(0.0, _wait - delta)
	if _wait > 0.0:
		_stage.queue_redraw()
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v != Vector2.ZERO:
		_swing = clampf(_swing + v.x * SWING_RATE * delta, -1.0, 1.0)
		_power = clampf(_power - v.y * POWER_RATE * delta, 0.1, 1.0)
		_refresh()
	if Input.is_action_just_pressed("run"):
		_loft = not _loft
		Audio.sfx("cursor")
		_refresh()
	if Input.is_action_just_pressed("confirm"):
		_throw()
	_stage.queue_redraw()

func _on_cancel() -> void:
	if _over or not _anim.is_empty():
		return
	close(null)

func _throw() -> void:
	var res := RoadBowling.throw_bowl(_v, _me.x, _me.y, _power, _swing, _loft, _rng, RoadBowling.wobble_scale(_easy), _easy)
	_my_throws += 1
	_begin(res, "me")
	Audio.sfx("atk_whoosh")
	_msg = ""
	_refresh()

func _their_turn() -> void:
	var res := RoadBowling.local_throw(_v, _rival, _them.x, _them.y, _rng)
	_their_throws += 1
	_begin(res, "them")
	Audio.sfx_at("atk_whoosh", -6.0, 0.85)

func _begin(res: Dictionary, who: String) -> void:
	var dur := (0.75 + float(res.d) / 170.0) * (1.0 if who == "me" else 0.7)
	_anim = {"res": res, "t": 0.0, "dur": dur, "who": who}

func _landed() -> void:
	var res: Dictionary = _anim.res
	var who: String = _anim.who
	_anim = {}
	var end := Vector2(float(res.s1), float(res.y1))
	var pts: PackedVector2Array = res.pts
	var stop := pts[pts.size() - 1]
	if who == "me":
		_me = end
		_marks.append(end)
	else:
		_them = end
	if bool(res.off):
		_puffs.append([stop, 0.0, "leaves"])
		Audio.sfx("bog_squelch")
	elif bool(res.finished):
		_puffs.append([stop, 0.0, "cheer"])
		Audio.sfx("badge")
	else:
		_puffs.append([stop, 0.0, "dust"])
		Audio.sfx_at("atk_thud", -4.0 if who == "them" else 0.0)
	var length := float(_v.get("length", 600))
	if who == "me":
		if bool(res.finished):
			_my_done = _my_throws
		_msg = "%s%s" % [RoadBowling.advice(res, bool(res.finished)), (" %d m to go." % maxi(0, roundi(length - _me.x))) if not bool(res.finished) else ""]
		_refresh()
		_wait = 0.45
		await get_tree().create_timer(0.7).timeout
		if is_inside_tree() and not _over:
			if _their_done == 0:
				_their_turn()
			else:
				_judge()
	else:
		if bool(res.finished):
			_their_done = _their_throws
		_judge()

## After each pair of throws: has anyone finished? Both throw the same number of times, so a draw is possible.
func _judge() -> void:
	_wait = 0.35
	var length := float(_v.get("length", 600))
	var who := str(_rival.get("who", "The local")).split(",")[0]
	if _my_done > 0 or _their_done > 0 or _my_throws >= RoadBowling.MAX_THROWS:
		_over = true
		var won := _my_done > 0 and (_their_done == 0 or _my_done < _their_done)
		var draw := _my_done > 0 and _my_done == _their_done
		if _my_done == 0:
			_my_done = RoadBowling.MAX_THROWS
		if won:
			_msg = "You are round in %d. %s %s." % [_my_done, who, "needed %d" % _their_done if _their_done > 0 else "is still out on the road"]
			Audio.sfx("level_up")
		elif draw:
			_msg = "Both over the line in %d. A dead heat, and a great deal of arguing." % _my_done
			Audio.sfx("confirm")
		else:
			_msg = "%s is round in %s. %s" % [who, str(_their_done) if _their_done > 0 else "the dark", "Fewer throws takes it."]
			Audio.sfx("cancel")
		_refresh()
		await get_tree().create_timer(2.2).timeout
		if not is_inside_tree():
			return
		await PiecePrompt.after_game(self, "road_bowling", float(_my_done))
		close({"won": won, "draw": draw, "throws": _my_done})
		return
	_msg += "  %s is %d m to go." % [who, maxi(0, roundi(length - _them.x))]
	_refresh()

func _follow_camera(delta: float) -> void:
	var focus_s := _me.x
	if not _anim.is_empty():
		var res: Dictionary = _anim.res
		focus_s = _anim_pos().x
		if str(_anim.who) == "them":
			focus_s = _anim_pos().x
		if res.is_empty():
			return
	var want_s := focus_s - WIN_M * 0.28
	var want_y := RoadBowling.centre(_v, want_s + WIN_M * 0.45)
	_cam.x = lerpf(_cam.x, want_s, clampf(delta * 3.5, 0.0, 1.0))
	_cam.y = lerpf(_cam.y, want_y, clampf(delta * 2.5, 0.0, 1.0))

## The animated bowl: (s, y) and its height above the road (metres, for the shadow and the size).
func _anim_pos() -> Vector2:
	var res: Dictionary = _anim.res
	var pts: PackedVector2Array = res.pts
	var f := clampf(float(_anim.t) / float(_anim.dur), 0.0, 1.0)
	f = 1.0 - pow(1.0 - f, 1.6)   # fast out of the hand, slowing as it rolls
	var fi := f * float(pts.size() - 1)
	var i := mini(int(fi), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], fi - float(i))

func _anim_height() -> float:
	if _anim.is_empty():
		return 0.0
	var res: Dictionary = _anim.res
	var p := _anim_pos()
	var s0: float = (res.pts as PackedVector2Array)[0].x
	var air := float(res.air_until) - s0
	var along := p.x - s0
	if bool(res.loft):
		var u := clampf(along / maxf(1.0, air / 1.0), 0.0, 1.0)
		if along <= air:
			return 11.0 * sin(u * PI)
		return 1.2 * absf(sin((along - air) * 0.35)) * maxf(0.0, 1.0 - (along - air) / 30.0)
	if along <= air:
		return 2.2 * absf(sin(along * 0.09)) * (1.0 - along / maxf(1.0, air) * 0.6)
	return 0.0

func _refresh() -> void:
	if _info == null:
		return
	var length := float(_v.get("length", 600))
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var side := "straight" if absf(_swing) < 0.05 else ("%d%% %s" % [roundi(absf(_swing) * 100.0), "right" if _swing > 0.0 else "left"])
	var lines := "Throw %d.  %d m to go.   Against %s (%d throws so far).\nPower %d%%.  Swing %s.%s" % [_my_throws + (0 if not _anim.is_empty() or _over else 1), maxi(0, roundi(length - _me.x)), who, _their_throws, roundi(_power * 100.0), side, "  LOFT" if _loft else ""]
	if _msg != "":
		lines += "\n" + _msg
	_info.text = lines
	_stage.queue_redraw()

# ---- drawing

func _sx(s: float) -> float:
	return (s - _cam.x) * (STAGE.x / WIN_M)

func _sy(y: float) -> float:
	return STAGE.y * 0.5 + (y - _cam.y) * (STAGE.x / WIN_M)

func _hash(i: int, salt: int) -> float:
	return float((i * 73856093 + salt * 19349663) & 0xffff) / 65535.0

func _draw_stage() -> void:
	var px := STAGE.x / WIN_M
	var s0 := _cam.x
	var s1 := _cam.x + WIN_M
	_draw_fields(s0, s1, px)
	var hw := _hw()
	var centre := PackedVector2Array()
	var st := s0 - 6.0
	while st <= s1 + 6.0:
		centre.append(Vector2(_sx(st), _sy(RoadBowling.centre(_v, st))))
		st += 4.0
	_stage.draw_polyline(centre, HEDGE, (hw + 11.0) * 2.0 * px, true)
	_draw_hedge_tufts(s0, s1, hw, px)
	_stage.draw_polyline(centre, DITCH, (hw + 5.0) * 2.0 * px, true)
	_stage.draw_polyline(centre, VERGE, (hw + 3.0) * 2.0 * px, true)
	_draw_verge_flowers(s0, s1, hw, px)
	_stage.draw_polyline(centre, TARMAC, hw * 2.0 * px, true)
	for side in [-1.0, 1.0]:
		var edge := PackedVector2Array()
		var e := s0 - 6.0
		while e <= s1 + 6.0:
			edge.append(Vector2(_sx(e), _sy(RoadBowling.centre(_v, e) + side * (hw - 0.5))))
			e += 4.0
		_stage.draw_polyline(edge, Color(0.86, 0.86, 0.8, 0.55), 1.5, true)
	_draw_centre_dashes(s0, s1, px)
	_draw_posts(s0, s1, hw, px)
	_draw_scouts(hw, px)
	_draw_line_at(0.0, hw, px, false)
	_draw_line_at(float(_v.get("length", 600)), hw, px, true)
	for m in _marks:
		_draw_chalk(m, px)
	_draw_bowl_rest(_them, Color("d9772c"), px, str(_rival.get("who", "")).substr(0, 1))
	_draw_bowl_rest(_me, Color("c9ccd4"), px, "")
	for p in _puffs:
		_draw_puff(p, px)
	if not _anim.is_empty():
		_draw_flying(px)
	elif not _over:
		_draw_aim(px)
	_draw_hud()
	# the edges fade out, as if looking down through a haze
	_stage.draw_rect(Rect2(0, 0, STAGE.x, 14), Color(0, 0, 0, 0.18))
	_stage.draw_rect(Rect2(0, STAGE.y - 14, STAGE.x, 14), Color(0, 0, 0, 0.18))

func _draw_fields(s0: float, s1: float, px: float) -> void:
	var chunk := 80.0
	var band := 40.0
	var i0 := floori(s0 / chunk)
	var i1 := floori(s1 / chunk)
	var y_top := _cam.y - (STAGE.y * 0.5) / px
	var y_bot := _cam.y + (STAGE.y * 0.5) / px
	var j0 := floori(y_top / band)
	var j1 := floori(y_bot / band)
	for i in range(i0, i1 + 1):
		for j in range(j0, j1 + 1):
			var col: Color = PATCH[absi(i * 7 + j * 3 + (i * j)) % PATCH.size()]
			var r := Rect2(_sx(i * chunk), _sy(j * band), chunk * px + 1.0, band * px + 1.0)
			_stage.draw_rect(r, col)
			var stripe := Color(1, 1, 1, 0.045)
			var k := 0.0
			while k < band * px:
				_stage.draw_rect(Rect2(r.position.x, r.position.y + k, r.size.x, 5.0), stripe)
				k += 12.0
			if _hash(i, j) > 0.62:   # a sheep or two
				var c := r.position + Vector2(_hash(j, i + 3), _hash(i + 5, j)) * r.size * 0.7 + r.size * 0.1
				_stage.draw_circle(c, 5.0, Color("efe9d8"))
				_stage.draw_circle(c + Vector2(5, 0), 2.6, Color("2a2622"))
				_stage.draw_circle(c + Vector2(-9, 1), 4.0, Color("efe9d8"))
				_stage.draw_circle(c + Vector2(-4, 5), 4.0, Color("efe9d8"))

func _draw_hedge_tufts(s0: float, s1: float, hw: float, px: float) -> void:
	var k := floori(s0 / 5.0)
	while float(k) * 5.0 <= s1 + 5.0:
		var s := float(k) * 5.0
		for side in [-1.0, 1.0]:
			var off: float = side * (hw + 9.0 + _hash(k, int(side) + 4) * 2.4)
			var c := Vector2(_sx(s), _sy(RoadBowling.centre(_v, s) + off))
			var shade := 0.85 + _hash(k, 9) * 0.3
			_stage.draw_circle(c, (3.4 + _hash(k, 2) * 2.4) * px / 3.8 * 1.4, Color(0.2 * shade, 0.42 * shade, 0.2 * shade))
			if _hash(k, 7) > 0.8:
				_stage.draw_circle(c + Vector2(2, -2), 1.8, Color("d9594a"))   # a haw
		k += 1

func _draw_verge_flowers(s0: float, s1: float, hw: float, px: float) -> void:
	var k := floori(s0 / 7.0)
	while float(k) * 7.0 <= s1:
		var s := float(k) * 7.0
		for side in [-1.0, 1.0]:
			var off: float = side * (hw + 1.4 + _hash(k, 11 + int(side)) * 1.2)
			var c := Vector2(_sx(s), _sy(RoadBowling.centre(_v, s) + off))
			_stage.draw_circle(c, 2.0, Color("f2eee0") if _hash(k, 5) > 0.4 else Color("e6c34a"))
		k += 1

func _draw_centre_dashes(s0: float, s1: float, px: float) -> void:
	# worn grass down the middle of a country lane, drawn as faint tufts
	var k := floori(s0 / 9.0)
	while float(k) * 9.0 <= s1:
		var s := float(k) * 9.0
		var c := Vector2(_sx(s), _sy(RoadBowling.centre(_v, s)))
		_stage.draw_rect(Rect2(c.x - 4, c.y - 1, 8, 2), Color(0.45, 0.5, 0.36, 0.5))
		k += 1

func _draw_posts(s0: float, s1: float, hw: float, px: float) -> void:
	var k := ceili(s0 / 100.0)
	while float(k) * 100.0 <= s1:
		var s := float(k) * 100.0
		if s > 0.0 and s < float(_v.get("length", 600)):
			var c := Vector2(_sx(s), _sy(RoadBowling.centre(_v, s) + hw + 2.2))
			_stage.draw_rect(Rect2(c.x - 3, c.y - 7, 6, 14), Color("efe9d8"))
			_stage.draw_string(ThemeDB.fallback_font, c + Vector2(6, 5), "%d" % int(s), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
		k += 1

func _draw_scouts(hw: float, px: float) -> void:
	var idx := 0
	for s in _v.get("scouts", []):
		var sx := _sx(float(s))
		if sx > -30.0 and sx < STAGE.x + 30.0:
			var side := 1.0 if idx % 2 == 0 else -1.0
			var c := Vector2(sx, _sy(RoadBowling.centre(_v, float(s)) + side * (hw + 1.6)))
			var bob := absf(sin(_clock * 3.0 + idx)) * 2.0 if not _anim.is_empty() else 0.0
			_stage.draw_circle(c + Vector2(0, 2), 9.0, Color(0, 0, 0, 0.18))
			_stage.draw_circle(c + Vector2(0, -bob), 7.0, Color("f08a24"))   # hi-vis
			_stage.draw_circle(c + Vector2(0, -bob - 1), 3.4, Color("e8c8a0"))
			_stage.draw_line(c + Vector2(-6, -bob), c + Vector2(-10, -bob - 6), Color("f08a24"), 3.0)
			_stage.draw_line(c + Vector2(6, -bob), c + Vector2(10, -bob - 6), Color("f08a24"), 3.0)
		idx += 1

func _draw_line_at(s: float, hw: float, px: float, finish: bool) -> void:
	var x := _sx(s)
	if x < -20.0 or x > STAGE.x + 20.0:
		return
	var cy := RoadBowling.centre(_v, s)
	if not finish:
		_stage.draw_line(Vector2(x, _sy(cy - hw)), Vector2(x, _sy(cy + hw)), Color(1, 1, 1, 0.85), 3.0)
		return
	var n := 8
	var h := hw * 2.0 * px / float(n)
	for r in n:
		for c in 3:
			var dark := (r + c) % 2 == 0
			_stage.draw_rect(Rect2(x - 12 + c * 8, _sy(cy - hw) + r * h, 8, h), Color("1c1c20") if dark else Color("f2f0e8"))
	for side in [-1.0, 1.0]:
		var top := Vector2(x, _sy(cy + side * (hw + 1.5)))
		_stage.draw_line(top, top + Vector2(0, -26), Color("efe9d8"), 3.0)
	var bx := x - 16.0
	var by := _sy(cy - hw - 1.5) - 26.0
	_stage.draw_rect(Rect2(bx, by, 32, 12), Color("c4523a"))
	_stage.draw_string(ThemeDB.fallback_font, Vector2(bx + 3, by + 10), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f8f1dc"))
	# a little crowd on the verge past the line
	for k in 7:
		var p := Vector2(x + 18 + float(k % 3) * 10.0, _sy(cy + (hw + 1.3 + float(k / 3)) * (1.0 if k % 2 == 0 else -1.0)))
		var up := absf(sin(_clock * 4.0 + k)) * 3.0 if _over else 0.0
		_stage.draw_circle(p + Vector2(0, -up), 5.0, [Color("5a7fb5"), Color("b55a6a"), Color("e8c872"), Color("6aaa7a")][k % 4])

func _draw_chalk(m: Vector2, px: float) -> void:
	var c := Vector2(_sx(m.x), _sy(m.y))
	if c.x < -20.0 or c.x > STAGE.x + 20.0:
		return
	_stage.draw_arc(c, 9.0, -0.9, 0.9, 8, Color(1, 1, 1, 0.75), 2.0)   # a bowler's chalk scrape
	_stage.draw_line(c + Vector2(-8, -3), c + Vector2(-2, 3), Color(1, 1, 1, 0.6), 2.0)

func _draw_bowl_rest(p: Vector2, col: Color, px: float, letter: String) -> void:
	if not _anim.is_empty() and str(_anim.who) == ("them" if col.r > 0.8 and col.g < 0.6 else "me"):
		return
	var c := Vector2(_sx(p.x), _sy(p.y))
	if c.x < -20.0 or c.x > STAGE.x + 20.0:
		if letter != "":
			var edge := clampf(c.x, 18.0, STAGE.x - 18.0)
			_stage.draw_colored_polygon(PackedVector2Array([Vector2(edge, 26), Vector2(edge + (10 if c.x > 0 else -10), 20), Vector2(edge + (10 if c.x > 0 else -10), 32)]), col)
		return
	_draw_ball(c, 0.0, col, px)

func _draw_ball(c: Vector2, height: float, col: Color, px: float) -> void:
	var lift := height * px * 0.6
	_stage.draw_circle(c + Vector2(2.0 + height * 0.5, 3.0), 6.5 * (1.0 - clampf(height * 0.02, 0.0, 0.3)), Color(0, 0, 0, 0.28))
	var r := 7.0 + height * 0.35
	_stage.draw_circle(c + Vector2(0, -lift), r, Color("2a2b30") if col.r > 0.8 and col.g > 0.7 else col.darkened(0.45))
	_stage.draw_circle(c + Vector2(0, -lift), r - 1.8, col.darkened(0.3))
	_stage.draw_circle(c + Vector2(-2.2, -2.6 - lift), 2.4, Color(1, 1, 1, 0.7))

func _draw_flying(px: float) -> void:
	var res: Dictionary = _anim.res
	var p := _anim_pos()
	var h := _anim_height()
	var col := Color("c9ccd4") if str(_anim.who) == "me" else Color("d9772c")
	var pts: PackedVector2Array = res.pts
	var trail := PackedVector2Array()
	for q in pts:
		if q.x <= p.x:
			trail.append(Vector2(_sx(q.x), _sy(q.y)))
	if trail.size() >= 2:
		_stage.draw_polyline(trail, Color(col.r, col.g, col.b, 0.35), 2.0, true)
	_draw_ball(Vector2(_sx(p.x), _sy(p.y)), h, col, px)

func _draw_puff(p: Array, px: float) -> void:
	var pos: Vector2 = p[0]
	var a := float(p[1])
	var c := Vector2(_sx(pos.x), _sy(pos.y))
	var fade := clampf(1.0 - a / 1.2, 0.0, 1.0)
	match str(p[2]):
		"dust":
			for k in 5:
				var ang := float(k) * 1.26
				_stage.draw_circle(c + Vector2(cos(ang), sin(ang)) * (6.0 + a * 22.0), 3.0 + a * 3.0, Color(0.82, 0.78, 0.68, 0.55 * fade))
		"leaves":
			for k in 8:
				var ang := float(k) * 0.785 + 0.3
				_stage.draw_circle(c + Vector2(cos(ang), sin(ang) - a * 1.2) * (6.0 + a * 26.0), 2.4, Color(0.3, 0.55, 0.25, fade))
			_stage.draw_string(ThemeDB.fallback_font, c + Vector2(-26, -22 - a * 14.0), "Nettles!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.9, 0.6, fade))
		"cheer":
			for k in 10:
				var ang := float(k) * 0.628
				_stage.draw_circle(c + Vector2(cos(ang), sin(ang)) * (8.0 + a * 40.0), 2.6, [Color("e8c872"), Color("c4523a"), Color("5a7fb5")][k % 3] * Color(1, 1, 1, fade))

func _draw_aim(px: float) -> void:
	# the line the bowl is aimed along, curving off with the swing; a short stub normally, the whole path when Easier
	var rng := Rng.new(1)
	var res := RoadBowling.throw_bowl(_v, _me.x, _me.y, _power, _swing, _loft, rng, 0.0, _easy)
	var pts: PackedVector2Array = res.pts
	var keep := pts.size() if _easy else maxi(2, int(pts.size() * 0.3))
	var k := 0
	for q in pts:
		if k >= keep:
			break
		if k % 2 == 0:
			var a := 0.8 - 0.5 * float(k) / float(maxi(1, keep))
			var col := Color(1.0, 0.92, 0.5, a)
			if _loft and q.x < float(res.air_until) and q.x - _me.x < float(res.d) * RoadBowling.LOFT_AIR:
				col = Color(0.7, 0.9, 1.0, a)
			_stage.draw_circle(Vector2(_sx(q.x), _sy(q.y)), 2.6, col)
		k += 1
	if _easy and bool(res.off):
		var q: Vector2 = pts[pts.size() - 1]
		_stage.draw_string(ThemeDB.fallback_font, Vector2(_sx(q.x) - 8, _sy(q.y) - 12), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e07060"))

func _draw_hud() -> void:
	# power bar (bottom left) and swing dial
	var x := 18.0
	var y := STAGE.y - 36.0
	_stage.draw_rect(Rect2(x - 4, y - 10, 232, 40), Color(0.1, 0.12, 0.16, 0.7))
	_stage.draw_rect(Rect2(x, y, 140, 12), Color(1, 1, 1, 0.15))
	_stage.draw_rect(Rect2(x, y, 140.0 * _power, 12), Color("e8c872"))
	_stage.draw_string(ThemeDB.fallback_font, Vector2(x, y - 1), "POWER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.CREAM)
	var c := Vector2(x + 188, y + 14)
	_stage.draw_arc(c, 20.0, PI, TAU, 18, Color(1, 1, 1, 0.3), 2.0)
	var a := -PI * 0.5 + _swing * PI * 0.45
	_stage.draw_line(c, c + Vector2(cos(a), sin(a)) * 19.0, Color("e8c872"), 3.0)
	if _loft:
		_stage.draw_rect(Rect2(STAGE.x - 96, 10, 84, 26), Color("3a5a7a"))
		_stage.draw_string(ThemeDB.fallback_font, Vector2(STAGE.x - 88, 29), "LOFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)
