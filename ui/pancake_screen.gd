extends MenuBase
## The Olney pancake race (story command {"do": "pancake"}): 415 yards of High Street with a frying pan. Toss the
## pancake to start, hold Run to sprint, lean the pan left and right to keep the pancake in it, and press Confirm as
## you pass each flag to flip it. Lowest time wins; a drop is a stop to scrape it up, a missed flip is a penalty. The
## rules live in Pancake. Closes with {"won": bool, "time": float, "champion": float} (null if you walk out).
## setup arg: "<seed>" or "dev" (dev: a race well under way with a flip about to be due).

const STAGE := Vector2(1090, 392)
const WPY := 13.0            # world pixels per yard
const RUN_X := 250.0
const FOOT_Y := 336.0
const ROAD_Y := 268.0
const BUILD_Y := 244.0
const PAN := Vector2(930, 108)    # the close-up of the pan

var _seed := 1
var _g: Pancake
var _champ := 48.0
var _state := "ready"
var _msg := ""
var _stage: Control
var _info: Label
var _easy := false
var _pops: Array = []
var _shake := 0.0
var _cheer := 0.0
var _step_t := 0.0
var _last_grade := ""
var _last_grade_t := 9.0
var _over := false
var _tilt := 0.0

func _build() -> void:
	set_title("Pancake race")
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
	set_hints([["confirm", "Flip"], ["move_left", "Lean the pan"], ["run", "Sprint"], ["cancel", "Walk away"]])
	_seed = int(Time.get_ticks_usec()) % 100000
	_reset()

func setup(arg: String) -> void:
	if arg.is_valid_int():
		_seed = int(arg)
	_reset()
	if arg.begins_with("dev"):
		_seed = 3
		_reset()
		_g.step(1.0 / 60.0, 0.0, false, true)
		_state = "run"
		while _g.y < Pancake.station_y(3) - 7.5:
			_g.step(1.0 / 60.0, clampf(_g.p * 2.6 + _g.pv * 0.7, -1.0, 1.0), true, false)
			if _g.next_station <= Pancake.STATIONS and absf(Pancake.station_y(_g.next_station) - _g.y) / maxf(_g.v, Pancake.JOG) < 0.04:
				_g.step(1.0 / 60.0, 0.0, true, true)
		_g.events.clear()
		_msg = "Flag 3 is coming. Press Confirm as you pass it."
	_refresh()

func _reset() -> void:
	_g = Pancake.new(_seed, _easy)
	_champ = Pancake.champion_time(_seed)
	_state = "ready"
	_msg = "Press Confirm to toss the pancake and start. Hold Run to sprint, lean the pan to keep it in, and flip at every flag."
	_pops.clear()
	_refresh()

func _on_cancel() -> void:
	if _over:
		return
	Audio.sfx("cancel")
	close(null)

func _process(delta: float) -> void:
	_cheer += delta
	_shake = maxf(0.0, _shake - delta)
	_last_grade_t += delta
	for p in _pops:
		p.t = float(p.t) + delta
	_pops = _pops.filter(func(p): return float(p.t) < 1.2)
	if _over:
		_stage.queue_redraw()
		return
	if _state == "ready":
		if Input.is_action_just_pressed("confirm") and not _locked:
			_g.step(delta, 0.0, false, true)
			_state = "run"
			_msg = ""
			Audio.sfx("bell_toll")
			Audio.sfx("snare_throw")
	elif _state == "run":
		_tilt = Input.get_axis("move_left", "move_right")
		_g.step(delta, _tilt, Input.is_action_pressed("run"), Input.is_action_just_pressed("confirm"))
		_step_t -= delta
		if _step_t <= 0.0 and _g.stopped <= 0.0:
			_step_t = 0.36 - 0.1 * clampf(_g.v / Pancake.SPRINT, 0.0, 1.0)
			Audio.sfx("step_path")
		for e in _g.events:
			_event(str(e))
		_g.events.clear()
		if _g.done:
			_finish()
	_stage.queue_redraw()
	_refresh()

func _event(e: String) -> void:
	var at := Vector2(RUN_X + 40.0, FOOT_Y - 170.0)
	if e.begins_with("flip:"):
		var grade := e.substr(5)
		_last_grade = grade
		_last_grade_t = 0.0
		match grade:
			"perfect":
				Audio.sfx("snare_throw")
				Audio.sfx("stat_up")
				_pops.append({"text": "PERFECT!", "pos": at, "t": 0.0, "col": Color("ffe27a")})
			"good":
				Audio.sfx("snare_throw")
				_pops.append({"text": "Good flip", "pos": at, "t": 0.0, "col": Color("c8f0a0")})
			"scruffy":
				Audio.sfx("snare_throw")
				Audio.sfx("cursor")
				_pops.append({"text": "Scruffy...", "pos": at, "t": 0.0, "col": Color("f0e8cc")})
			_:
				Audio.sfx("stat_down")
				var pen := Pancake.FINISH_MISS_PENALTY if _g.next_station >= Pancake.STATIONS else Pancake.MISS_PENALTY
				_pops.append({"text": "Missed it! +%.1fs" % pen, "pos": at, "t": 0.0, "col": Color("ff9a7a")})
	elif e == "drop":
		_shake = 0.3
		Audio.sfx("bump")
		Audio.sfx("hit_weak")
		_pops.append({"text": "DROPPED IT!", "pos": at, "t": 0.0, "col": Color("ff8a6a")})
	elif e == "pickup":
		Audio.sfx("scramble")
		_pops.append({"text": "...and back in the pan", "pos": at, "t": 0.0, "col": Color("f0e8cc")})
	elif e == "near_rim":
		Audio.sfx("cursor")

func _finish() -> void:
	var tt := _g.total()
	var beat := tt < _champ
	_state = "result"
	_over = true
	Audio.sfx("level_up" if beat else "confirm")
	_cheer = 0.0
	_msg = _g.verdict(_champ)
	_refresh()
	await get_tree().create_timer(2.6).timeout
	await PiecePrompt.after_game(self, "pancake", snappedf(tt, 0.1))
	close({"won": beat, "time": tt, "champion": _champ, "drops": _g.drops, "perfect": _g.count("perfect")})

func _refresh() -> void:
	if _info == null:
		return
	var l := ""
	if _state == "run":
		var flag := mini(_g.next_station, Pancake.STATIONS)
		l = "Time %.1f   Flag %d of %d   Drops %d   The champion is on %.1f." % [_g.total(), flag, Pancake.STATIONS, _g.drops, _champ]
	elif _state == "ready":
		l = "The champion's time today is %.1f seconds. Gold needs %.0f, silver %.0f." % [_champ, Pancake.MASTER_TIME, Pancake.GOOD_TIME]
	if _msg != "":
		l += "\n" + _msg
	_info.text = l

# ---- drawing

func _draw_stage() -> void:
	var w := STAGE.x
	var camx := _g.y * WPY - RUN_X
	var off := Vector2.ZERO
	if _shake > 0.0:
		off = Vector2(sin(_shake * 80.0), cos(_shake * 60.0)) * 4.0
	_stage.draw_set_transform(off, 0.0, Vector2.ONE)
	FolkArt.sky(_stage, Rect2(-10, -10, w + 20, BUILD_Y + 20), Color("9ec6e6"), Color("f6e4c0"))
	FolkArt.cloud(_stage, Vector2(fposmod(220.0 - camx * 0.04, w + 200.0) - 60.0, 44), 28.0)
	FolkArt.cloud(_stage, Vector2(fposmod(700.0 - camx * 0.05, w + 200.0) - 60.0, 70), 22.0, Color(1, 1, 1, 0.7))
	FolkArt.ridge(_stage, BUILD_Y - 30, w, 40.0, Color("a8b8a0"), 2.2, camx * 0.12, 0.006)
	_draw_street(camx)
	_draw_flags(camx)
	_draw_finish(camx)
	_draw_champion(camx)
	_draw_player()
	_draw_pan_inset()
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in _pops:
		var u := float(p.t) / 1.2
		var col: Color = p.col
		col.a = 1.0 - u * u
		var pos: Vector2 = p.pos + Vector2(-50, -u * 44.0)
		_stage.draw_string(ThemeDB.fallback_font, pos + Vector2(2, 2), str(p.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(0, 0, 0, col.a * 0.6))
		_stage.draw_string(ThemeDB.fallback_font, pos, str(p.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, col)
	if _state == "ready":
		_stage.draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 220, 120), "Olney, Shrove Tuesday", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("fff8e0"))
		_stage.draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 220, 156), "415 yards. Apron and headscarf are compulsory.", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f0e8cc"))
	# the progress strip along the bottom
	var by := STAGE.y - 16.0
	_stage.draw_rect(Rect2(40, by, w - 80, 6), Color(0.05, 0.07, 0.1, 0.5))
	for i in range(1, Pancake.STATIONS + 1):
		_stage.draw_rect(Rect2(40 + (w - 80) * float(i) / Pancake.STATIONS - 1, by - 3, 3, 12), Color("f0e8cc", 0.8))
	_stage.draw_circle(Vector2(40 + (w - 80) * clampf(_g.y / Pancake.LENGTH, 0.0, 1.0), by + 3), 7.0, Color("5ab0ff"))
	if _g.started:
		_stage.draw_circle(Vector2(40 + (w - 80) * clampf(_g.t / _champ, 0.0, 1.0), by + 3), 5.0, Color("ffd27a"))

func _draw_street(camx: float) -> void:
	var w := STAGE.x
	# a terrace of Georgian-ish fronts, a second row behind, parallax half speed
	var span := 168.0
	var par := camx * 0.55
	var first := int(floorf(par / span))
	for i in range(first - 1, first + int(w / span) + 3):
		var seedn := hash(i * 7 + 13)
		var hgt := 120.0 + float(seedn % 5) * 16.0
		var x0 := float(i) * span - par
		var wall: Color = [Color("c9a27a"), Color("b8806a"), Color("d8c49a"), Color("a89a86"), Color("c98a62"), Color("d9b48a")][seedn % 6]
		_stage.draw_rect(Rect2(x0, BUILD_Y - hgt, span - 6.0, hgt), wall)
		_stage.draw_rect(Rect2(x0, BUILD_Y - hgt, span - 6.0, 6.0), wall.darkened(0.2))
		_stage.draw_colored_polygon(PackedVector2Array([Vector2(x0 - 6, BUILD_Y - hgt), Vector2(x0 + span * 0.5 - 3, BUILD_Y - hgt - 34), Vector2(x0 + span - 6 + 6, BUILD_Y - hgt)]), Color("6b4a42") if seedn % 2 == 0 else Color("56606a"))
		_stage.draw_rect(Rect2(x0 + span * 0.68, BUILD_Y - hgt - 40, 14, 28), wall.darkened(0.3))   # a chimney
		for row in 2:
			for col in 3:
				var wx := x0 + 14.0 + col * 48.0
				var wy := BUILD_Y - hgt + 14.0 + row * 46.0
				if row == 1 and col == 1:
					continue
				_stage.draw_rect(Rect2(wx, wy, 26, 34), Color("3b4a5a"))
				_stage.draw_rect(Rect2(wx + 2, wy + 2, 10, 14), Color("7aa0b8") if (seedn + row + col) % 3 else Color("e8d08a"))
				_stage.draw_rect(Rect2(wx - 3, wy + 34, 32, 4), Color("e8e0cc"))
		_stage.draw_rect(Rect2(x0 + 55, BUILD_Y - 58, 38, 58), Color("3e5f4e") if seedn % 2 == 0 else Color("7a2f32"))
		_stage.draw_circle(Vector2(x0 + 86, BUILD_Y - 30), 2.5, Color("e8c872"))
		if seedn % 3 == 0:   # an awning
			for k in 6:
				_stage.draw_rect(Rect2(x0 + 8 + k * 24, BUILD_Y - 74, 24, 16), Color("b83a32") if k % 2 == 0 else Color("f4efe0"))
	# pavement, spectators, and the road with its cobbles
	_stage.draw_rect(Rect2(-10, BUILD_Y, w + 20, ROAD_Y - BUILD_Y), Color("b4aa98"))
	_stage.draw_rect(Rect2(-10, ROAD_Y - 3, w + 20, 5), Color("8a8272"))
	var sp := 74.0
	var f2 := int(floorf(camx / sp))
	for i in range(f2 - 1, f2 + int(w / sp) + 2):
		if i < 0:
			continue
		var x := float(i) * sp - camx + float(hash(i) % 30)
		var near := absf(x - RUN_X) < 260.0 and _g.started
		FolkArt.spectator(_stage, Vector2(x, BUILD_Y + 28.0), 66.0 + float(hash(i * 3) % 12), i, _cheer if (near or _g.done) else 0.0)
	_stage.draw_rect(Rect2(-10, ROAD_Y, w + 20, STAGE.y - ROAD_Y + 10), Color("8f877a"))
	_stage.draw_rect(Rect2(-10, ROAD_Y, w + 20, 6), Color("a39b8c"))
	var cs := 46.0
	var c0 := int(floorf(camx / cs))
	for i in range(c0 - 1, c0 + int(w / cs) + 2):
		for r in 4:
			var cx := float(i) * cs - camx + (cs * 0.5 if r % 2 == 1 else 0.0)
			var cy := ROAD_Y + 14.0 + r * 28.0
			_stage.draw_rect(Rect2(cx, cy, cs - 4.0, 22.0), Color("9c9484") if (i + r) % 3 else Color("867e70"))
	# bunting across the street
	for i in range(f2 - 1, f2 + int(w / 330.0) + 3):
		var bx := float(i) * 330.0 - camx * 0.8
		FolkArt.bunting(_stage, Vector2(bx, BUILD_Y - 150), Vector2(bx + 330.0, BUILD_Y - 150), 22.0)

func _draw_flags(camx: float) -> void:
	for i in range(0, Pancake.STATIONS + 1):
		var x := Pancake.station_y(i) * WPY - camx
		if x < -40.0 or x > STAGE.x + 40.0:
			continue
		var next := i == _g.next_station and _state == "run"
		_stage.draw_rect(Rect2(x - 2, ROAD_Y - 110, 4, 112), Color("e8e0cc"))
		var col := Color("e8a92e") if next else Color("b83a32")
		_stage.draw_colored_polygon(PackedVector2Array([Vector2(x + 2, ROAD_Y - 108), Vector2(x + 50, ROAD_Y - 92), Vector2(x + 2, ROAD_Y - 76)]), col)
		if i > 0 and i < Pancake.STATIONS:
			_stage.draw_string(ThemeDB.fallback_font, Vector2(x + 10, ROAD_Y - 85), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff8e0"))
		_stage.draw_rect(Rect2(x - 1, ROAD_Y + 4, 3, 130), Color(col, 0.35))   # a chalk line across the road
	if _state == "ready":
		var sx := -camx
		_stage.draw_string(ThemeDB.fallback_font, Vector2(sx + 70, ROAD_Y - 120), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("b83a32"))

func _draw_finish(camx: float) -> void:
	var fx := Pancake.LENGTH * WPY - camx
	if fx > STAGE.x + 700.0:
		return
	# the church: tower, nave, spire, door, with the verger and the prayer book at the finish
	var cx := fx + 260.0
	_stage.draw_rect(Rect2(cx - 150, ROAD_Y - 190, 300, 190), Color("b9b2a0"))
	_stage.draw_rect(Rect2(cx - 150, ROAD_Y - 196, 300, 8), Color("8f897a"))
	for k in 4:
		_stage.draw_rect(Rect2(cx - 120 + k * 72, ROAD_Y - 150, 22, 58), Color("34475a"))
		_stage.draw_colored_polygon(PackedVector2Array([Vector2(cx - 120 + k * 72, ROAD_Y - 150), Vector2(cx - 109 + k * 72, ROAD_Y - 168), Vector2(cx - 98 + k * 72, ROAD_Y - 150)]), Color("34475a"))
	_stage.draw_rect(Rect2(cx - 52, ROAD_Y - 300, 104, 112), Color("a8a18f"))
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(cx - 58, ROAD_Y - 300), Vector2(cx, ROAD_Y - 400), Vector2(cx + 58, ROAD_Y - 300)]), Color("6b7480"))
	_stage.draw_rect(Rect2(cx - 20, ROAD_Y - 96, 40, 96), Color("5a3a2a"))
	_stage.draw_arc(Vector2(cx, ROAD_Y - 96), 20.0, PI, TAU, 12, Color("5a3a2a"), 3.0)
	_stage.draw_circle(Vector2(cx, ROAD_Y - 262), 16.0, Color("f4efe0"))
	_stage.draw_line(Vector2(cx, ROAD_Y - 262), Vector2(cx, ROAD_Y - 274), Color("2c2a28"), 2.0)
	_stage.draw_line(Vector2(cx, ROAD_Y - 262), Vector2(cx + 8, ROAD_Y - 258), Color("2c2a28"), 2.0)
	FolkArt.spectator(_stage, Vector2(cx - 62, ROAD_Y + 8), 90.0, 5, _cheer if _g.done else 0.0)
	_stage.draw_string(ThemeDB.fallback_font, Vector2(cx - 112, ROAD_Y + 34), "the verger", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff8e0", 0.85))
	# the finish tape
	var by := ROAD_Y
	for k in 12:
		_stage.draw_rect(Rect2(fx - 3, by + 4 + k * 11, 6, 11), Color("f4efe0") if k % 2 == 0 else Color("2c2a28"))

## Draws the champion as a small figure keeping her pace along the street.
func _draw_champion(camx: float) -> void:
	if not _g.started:
		return
	var cy := minf(Pancake.LENGTH * _g.t / _champ, Pancake.LENGTH)
	var x := cy * WPY - camx
	if x < -60.0 or x > STAGE.x + 60.0:
		return
	_draw_woman(Vector2(x, ROAD_Y + 52.0), 120.0, cy * 0.9, 3, false, 0.0)
	_stage.draw_string(ThemeDB.fallback_font, Vector2(x - 40, ROAD_Y + 52.0 - 128.0), "Champion", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff8e0", 0.85))

## A runner in profile facing right: headscarf, apron over a dress, legs that scissor, a pan held out in front.
func _draw_woman(foot: Vector2, s: float, phase: float, idx: int, with_pan: bool, lean: float) -> void:
	var dress: Color = FolkArt.COATS[idx % FolkArt.COATS.size()]
	var skin: Color = FolkArt.SKIN[idx % FolkArt.SKIN.size()]
	var sw := sin(phase) * s * 0.2
	_stage.draw_circle(foot + Vector2(0, 2), s * 0.26, Color(0, 0, 0, 0.18))
	_stage.draw_line(foot + Vector2(0, -s * 0.42), foot + Vector2(sw, 0), Color("33353f"), maxf(3.0, s * 0.09))
	_stage.draw_line(foot + Vector2(0, -s * 0.42), foot + Vector2(-sw, 0), Color("4a4d58"), maxf(3.0, s * 0.09))
	_stage.draw_colored_polygon(PackedVector2Array([foot + Vector2(-s * 0.15, -s * 0.8), foot + Vector2(s * 0.15, -s * 0.8), foot + Vector2(s * 0.2, -s * 0.36), foot + Vector2(-s * 0.2, -s * 0.36)]), dress)
	_stage.draw_colored_polygon(PackedVector2Array([foot + Vector2(-s * 0.06, -s * 0.76), foot + Vector2(s * 0.17, -s * 0.76), foot + Vector2(s * 0.19, -s * 0.38), foot + Vector2(-s * 0.04, -s * 0.38)]), Color("f4efe0"))   # the apron
	_stage.draw_circle(foot + Vector2(s * 0.03, -s * 0.92), s * 0.13, skin)
	_stage.draw_circle(foot + Vector2(-s * 0.02, -s * 0.96), s * 0.14, Color("b83a32") if idx != 3 else Color("2f6d9a"))   # the headscarf
	_stage.draw_line(foot + Vector2(-s * 0.1, -s * 0.9), foot + Vector2(-s * 0.26, -s * 0.8 - sw * 0.2), Color("b83a32") if idx != 3 else Color("2f6d9a"), maxf(2.0, s * 0.05))
	var hand := foot + Vector2(s * 0.42, -s * 0.58)
	_stage.draw_line(foot + Vector2(s * 0.08, -s * 0.7), hand, skin, maxf(3.0, s * 0.07))
	if with_pan:
		_stage.draw_set_transform(hand, lean * 0.5, Vector2.ONE)
		_stage.draw_line(Vector2(-s * 0.02, 0), Vector2(s * 0.22, 0), Color("2c2a28"), maxf(2.0, s * 0.05))
		_stage.draw_line(Vector2(s * 0.22, 0), Vector2(s * 0.52, 0), Color("4a4d58"), maxf(3.0, s * 0.07))
		_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_stage.draw_line(hand, hand + Vector2(s * 0.16, 0), Color("4a4d58"), maxf(3.0, s * 0.06))

func _draw_player() -> void:
	var foot := Vector2(RUN_X, FOOT_Y)
	if _g.stopped > 0.0:
		_draw_woman(foot + Vector2(0, 0), 150.0, 0.0, 1, true, 0.0)
		_stage.draw_string(ThemeDB.fallback_font, foot + Vector2(-20, -170), "scraping it up...", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f0e8cc"))
		# the pancake on the cobbles
		_stage.draw_set_transform(foot + Vector2(130, 8), 0.0, Vector2(1.0, 0.3))
		_stage.draw_circle(Vector2.ZERO, 26.0, Color("d9a860"))
		_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_draw_woman(foot, 150.0, _g.y * 0.8, 1, true, _g.lean)
	# the pancake on the pan in the world, up in the air when flipped
	if _g.stopped <= 0.0:
		var hand := foot + Vector2(150.0 * 0.42, -150.0 * 0.58)
		var pan_c := hand + Vector2(150.0 * 0.38, -3)
		if _g.air > 0.0:
			var u := 1.0 - _g.air / Pancake.FLIP_AIR
			var hgt := sin(u * PI) * 120.0
			_stage.draw_set_transform(pan_c + Vector2(0, -hgt - 8), 0.0, Vector2(1.0, absf(cos(u * TAU)) * 0.8 + 0.12))
			_stage.draw_circle(Vector2.ZERO, 20.0, Color("e0b168") if u < 0.5 else Color("c98a3e"))
			_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			_stage.draw_set_transform(pan_c + Vector2(_g.p * 22.0, -9), 0.0, Vector2(1.0, 0.35))
			_stage.draw_circle(Vector2.ZERO, 18.0, Color("e0b168"))
			_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pan_inset() -> void:
	var c := PAN
	_stage.draw_rect(Rect2(c.x - 140, c.y - 82, 280, 178), Color(0.06, 0.07, 0.1, 0.55))
	_stage.draw_rect(Rect2(c.x - 140, c.y - 82, 280, 178), Color("f0e8cc", 0.35), false, 2.0)
	var tilt := _g.lean * 0.35
	var pc := c + Vector2(0, 38)
	# warm/cold rim zones so the danger is readable
	var edge := absf(_g.p)
	var rim_col := Color("e8d8b8").lerp(Color("ff5a4a"), clampf((edge - 0.55) / 0.4, 0.0, 1.0))
	_stage.draw_set_transform(pc, tilt, Vector2.ONE)
	_stage.draw_rect(Rect2(-100, -4, 200, 8), Color("3a3d46"))
	_stage.draw_rect(Rect2(-104, -16, 8, 20), rim_col)
	_stage.draw_rect(Rect2(96, -16, 8, 20), rim_col)
	_stage.draw_rect(Rect2(100, -4, 70, 7), Color("2c2a28"))   # the handle
	if _g.air > 0.0:
		_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var u := 1.0 - _g.air / Pancake.FLIP_AIR
		_stage.draw_set_transform(pc + Vector2(0, -sin(u * PI) * 66.0 - 14.0), 0.0, Vector2(1.0, absf(cos(u * TAU)) * 0.8 + 0.12))
		_stage.draw_circle(Vector2.ZERO, 30.0, Color("e0b168") if u < 0.5 else Color("c98a3e"))
	else:
		_stage.draw_set_transform(pc + Vector2(0, 0), tilt, Vector2.ONE)
		_stage.draw_set_transform(pc, tilt, Vector2.ONE)
		var pp := Vector2(_g.p * 70.0, -11.0)
		_stage.draw_set_transform(pc + Vector2(cos(tilt), sin(tilt)) * pp.x + Vector2(sin(tilt), -cos(tilt)) * 11.0, tilt, Vector2(1.0, 0.36))
		_stage.draw_circle(Vector2.ZERO, 32.0, Color("e0b168"))
		_stage.draw_circle(Vector2(-8, -3), 5.0, Color("c98a3e"))
		_stage.draw_circle(Vector2(10, 6), 4.0, Color("c98a3e"))
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the flip ring: it closes on the pan as the flag arrives
	var pr := _g.prompt() if _state == "run" else -1.0
	var ring_c := c + Vector2(0, -22)
	if pr >= 0.0:
		var r := lerpf(66.0, 24.0, clampf(pr, 0.0, 1.0)) if pr <= 1.0 else 24.0 - (pr - 1.0) * 8.0
		var win: Dictionary = _g.windows()
		var good := absf(pr - 1.0) < 0.2
		_stage.draw_arc(ring_c, 24.0, 0.0, TAU, 28, Color("c8f0a0") if good else Color("f0e8cc", 0.8), 4.0)
		_stage.draw_arc(ring_c, maxf(r, 6.0), 0.0, TAU, 28, Color("ffd27a"), 3.0)
		_stage.draw_string(ThemeDB.fallback_font, ring_c + Vector2(-30, -74), "FLIP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("ffe27a") if good else Color("f0e8cc"))
		if win.is_empty():
			pass
	elif _last_grade_t < 0.8 and _last_grade != "":
		_stage.draw_string(ThemeDB.fallback_font, ring_c + Vector2(-44, -70), _last_grade.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe27a"))
	_stage.draw_string(ThemeDB.fallback_font, c + Vector2(-130, 88), "keep it off the rim", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f0e8cc", 0.75))
