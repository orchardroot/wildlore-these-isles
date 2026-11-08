extends MenuBase
## Cheese rolling (story command {"do": "cheese"}): three downhill races on Cooper's Hill. Steer left and right to
## dodge the tussocks and rabbit holes, hold Run to dig your heels in, and chase the cheese. First to the bottom wins
## it; a tumble costs a moment, never the race. The rules and numbers live in CheeseRoll. Closes with
## {"won": bool, "best": int, "places": Array} (null if you walk out before the first race ends).
## setup arg: "<seed>" or "dev" (dev: a race part way down the slope, mid-tumble).

const STAGE := Vector2(900, 392)
const HORIZON := 96.0
const RUN_Y := 318.0
const HALF := 330.0          # pixels from the middle to a lane edge at the runner
const SAMPLES := 17

var _seed := 0
var _heat := 0
var _g: CheeseRoll
var _state := "ready"        # ready, count, run, result
var _count := 0.0
var _places: Array = []
var _scores: Array = []
var _msg := ""
var _stage: Control
var _info: Label
var _easy := false
var _shake := 0.0
var _flash := 0.0
var _pops: Array = []        # {text, pos, t, col}
var _step_t := 0.0
var _cheer := 0.0
var _result_wait := 0.0
var _over := false

func _build() -> void:
	set_title("Cheese rolling")
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
	set_hints([["confirm", "Start"], ["move_left", "Steer"], ["run", "Dig in"], ["cancel", "Walk away"]])
	_seed = int(Time.get_ticks_usec()) % 100000
	_new_heat()

func setup(arg: String) -> void:
	if arg.is_valid_int():
		_seed = int(arg)
	if arg.begins_with("dev"):
		_seed = 7
		_new_heat()
		_state = "run"
		while _g.t < 6.0 and not _g.done:
			var steer := 0.0
			for o in _g.obstacles:
				var d: float = float(o.y) - _g.y
				if d > 0.0 and d < 14.0 and absf(float(o.x) - _g.x) < 0.3:
					steer = 1.0 if _g.x >= float(o.x) else -1.0
			_g.step(1.0 / 60.0, steer, false)
		_g.tumble = 0.0
		_g.events.clear()
		_msg = "Dodge the tussocks. Hold Run to dig your heels in."
		_pops.append({"text": "Oof!", "pos": Vector2(540, 250), "t": 0.2, "col": Color("ffd27a")})
	elif arg.is_valid_int():
		_new_heat()
	_refresh()

func _new_heat() -> void:
	_g = CheeseRoll.new(_seed + _heat * 31, _easy)
	_state = "ready"
	_msg = "Confirm when you are at the top and ready to go."   # the info line already names the heat
	_pops.clear()
	_refresh()

func _on_cancel() -> void:
	if _over:
		return
	Audio.sfx("cancel")
	close(null if _places.is_empty() else _summary())

func _summary() -> Dictionary:
	var best := 0
	for s in _scores:
		best = maxi(best, int(s))
	return {"won": _places.has(1), "best": best, "places": _places.duplicate()}

func _process(delta: float) -> void:
	_cheer += delta
	_shake = maxf(0.0, _shake - delta)
	_flash = maxf(0.0, _flash - delta)
	for p in _pops:
		p.t = float(p.t) + delta
	_pops = _pops.filter(func(p): return float(p.t) < 1.1)
	if _over:
		_stage.queue_redraw()
		return
	match _state:
		"ready":
			if Input.is_action_just_pressed("confirm") and not _locked:
				_state = "count"
				_count = 3.0
				Audio.sfx("cursor")
				_msg = ""
		"count":
			var before := ceili(_count)
			_count -= delta
			if ceili(_count) != before and _count > 0.0:
				Audio.sfx("cursor")
			if _count <= 0.0:
				_state = "run"
				Audio.sfx("bell_toll")
				_msg = ""
		"run":
			_run(delta)
		"result":
			_result_wait -= delta
			if _result_wait <= 0.0 and Input.is_action_just_pressed("confirm"):
				_next()
	_stage.queue_redraw()
	_refresh()

func _run(delta: float) -> void:
	var steer := Input.get_axis("move_left", "move_right")
	var was_tumbling := _g.tumble > 0.0
	_g.step(delta, steer, Input.is_action_pressed("run"))
	_step_t -= delta
	if _step_t <= 0.0 and _g.tumble <= 0.0:
		_step_t = 0.34 - 0.1 * clampf(_g.v / CheeseRoll.MAX_V, 0.0, 1.0)
		Audio.sfx("step_grass")
	for e in _g.events:
		_event(str(e), was_tumbling)
	_g.events.clear()
	if _g.done:
		_finish_heat()

func _event(e: String, _was: bool) -> void:
	var at := Vector2(_sw() * 0.5 + _g.x * 120.0, RUN_Y - 100.0)
	match e:
		"trip:tussock":
			_shake = 0.35
			_flash = 0.25
			Audio.sfx("bump")
			Audio.sfx("hit_weak")
			_pops.append({"text": "TUSSOCK!", "pos": at, "t": 0.0, "col": Color("ffd27a")})
		"trip:burrow":
			_shake = 0.35
			_flash = 0.25
			Audio.sfx("bump")
			Audio.sfx("hit")
			_pops.append({"text": "RABBIT HOLE!", "pos": at, "t": 0.0, "col": Color("ffb27a")})
		"trip:puddle":
			Audio.sfx("splash")
			_pops.append({"text": "splosh", "pos": at, "t": 0.0, "col": Color("a8d8f0")})
		"scrape":
			Audio.sfx("scramble")
			_pops.append({"text": "Mind the crowd!", "pos": at, "t": 0.0, "col": Color("f0e8cc")})
		"catch":
			Audio.sfx("caught")
			_flash = 0.3
			_pops.append({"text": "GOT THE CHEESE!", "pos": at + Vector2(0, -26), "t": 0.0, "col": Color("ffe27a")})
		"stall":
			Audio.sfx("atk_thud")
		_:
			if e.begins_with("rival_trip:"):
				Audio.sfx("hit_weak")
				_pops.append({"text": "%s goes over!" % e.substr(11), "pos": Vector2(_sw() * 0.5, 130.0), "t": 0.0, "col": Color("f0e8cc")})

func _finish_heat() -> void:
	_places.append(_g.place)
	_scores.append(_g.score())
	Audio.sfx("level_up" if _g.place == 1 else ("confirm" if _g.place < 4 else "cancel"))
	_msg = "%s  (%d points)" % [_g.verdict(), _g.score()]
	_state = "result"
	_result_wait = 0.9
	_cheer = 0.0

func _next() -> void:
	_heat += 1
	if _heat >= CheeseRoll.HEATS:
		_over = true
		var s := _summary()
		_msg = "The evening is over. Best heat: %d points. %s" % [int(s.best), "You won a race, and a cheese." if bool(s.won) else "No cheese, but you walked off the hill."]
		_refresh()
		await get_tree().create_timer(1.8).timeout
		await PiecePrompt.after_game(self, "cheese", float(s.best))
		close(s)
		return
	_new_heat()

func _refresh() -> void:
	if _info == null:
		return
	var l := ""
	if _g != null:
		var steer_tip := ""
		match _state:
			"run":
				steer_tip = "Place %s.  Tumbles %d.  %s" % [_place_now(), _g.tumbles, "Cheese caught." if _g.caught else "Chase the cheese."]
			"count":
				steer_tip = "Get set..."
		l = "Heat %d of %d.   %s" % [mini(_heat + 1, CheeseRoll.HEATS), CheeseRoll.HEATS, steer_tip]
	if _msg != "":
		l += "\n" + _msg
	if _easy and _state == "ready":
		l += "\n" + CheeseRoll.easier_text()
	_info.text = l

func _place_now() -> String:
	var p := 1
	for r in _g.rivals:
		if float(r.y) > _g.y:
			p += 1
	return "%d of 4" % p

# ---- drawing

func _sw() -> float:
	return maxf(_stage.size.x, 600.0) if _stage != null else STAGE.x

## Screen position and scale of a spot `d` yards ahead and `lane` across the slope.
func _pt(d: float, lane: float) -> Vector3:
	var dd := maxf(d, -1.6)
	var s := 6.0 / (dd + 6.0)
	var cam := _g.x * 0.55
	return Vector3(_sw() * 0.5 + (lane - cam) * HALF * s, HORIZON + (RUN_Y - HORIZON) * s, s)

func _quad(d0: float, d1: float, l0: float, l1: float, col: Color) -> void:
	var a := _pt(d0, l0)
	var b := _pt(d0, l1)
	var c := _pt(d1, l1)
	var d := _pt(d1, l0)
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(a.x, a.y), Vector2(b.x, b.y), Vector2(c.x, c.y), Vector2(d.x, d.y)]), col)

func _draw_stage() -> void:
	var w := _sw()
	var off := Vector2.ZERO
	if _shake > 0.0:
		off = Vector2(sin(_shake * 90.0), cos(_shake * 70.0)) * 5.0 * (_shake / 0.35)
	_stage.draw_set_transform(off, 0.0, Vector2.ONE)
	var along := _g.y if _g != null else 0.0
	var cam := _g.x * 0.55 if _g != null else 0.0
	# sky, sun, clouds, far hills, far trees
	FolkArt.sky(_stage, Rect2(-10, -10, w + 20, HORIZON + 14), Color("7fb4e0"), Color("f6dcae"))
	FolkArt.sun(_stage, Vector2(w - 190 - cam * 30.0, 56), 24.0, Color("fff2c4"))
	FolkArt.cloud(_stage, Vector2(180 - cam * 18.0 + fposmod(_cheer * 3.0, 40.0), 38), 26.0)
	FolkArt.cloud(_stage, Vector2(560 - cam * 18.0, 24), 20.0, Color(1, 1, 1, 0.7))
	FolkArt.ridge(_stage, HORIZON - 6, w, 34.0, Color("9bb0a0"), 1.3, cam * 60.0, 0.006)
	FolkArt.ridge(_stage, HORIZON + 4, w, 24.0, Color("7f9f6a"), 4.1, cam * 110.0, 0.009)
	for i in 9:
		FolkArt.tree(_stage, Vector2(fposmod(60.0 + i * 131.0 - cam * 150.0, w + 100.0) - 50.0, HORIZON + 6), 26.0 + (i % 3) * 5.0, Color("5b8a42"))
	# the slope: verges, then the hill itself in mown stripes, drawn far to near
	var base := floorf(along / 5.0) * 5.0
	for k in range(SAMPLES, -1, -1):
		var d0 := base + k * 5.0 - along
		var d1 := d0 + 5.0
		if d0 > CheeseRoll.SEE + 20.0:
			continue
		var even := (int(base / 5.0) + k) % 2 == 0
		_quad(d0, d1, -4.0, 4.0, Color("7ba04a") if even else Color("86ab52"))
		_quad(d0, d1, -1.16, 1.16, Color("a6c85e") if even else Color("b2d268"))
		_quad(d0, d1, -1.16, -1.08, Color("6e5a3c"))
		_quad(d0, d1, 1.08, 1.16, Color("6e5a3c"))
	# the finish at the bottom and the start flag
	var fd := CheeseRoll.LENGTH - along
	if fd < CheeseRoll.SEE + 20.0:
		_quad(fd, fd + 3.0, -1.16, 1.16, Color("f4efe0"))
		for i in 8:
			_quad(fd, fd + 1.5, -1.16 + i * 0.29, -1.16 + i * 0.29 + 0.145, Color("2c2a28"))
	# spectators and fence posts down both sides
	var first := floorf(along / 6.0) * 6.0
	for k in range(14, -1, -1):
		var dd := first + k * 6.0 - along
		if dd < -1.6 or dd > CheeseRoll.SEE:
			continue
		for side in [-1.0, 1.0]:
			for row in 2:
				var a := _pt(dd + row * 2.0, side * (1.34 + row * 0.22))
				var idx := int(first / 6.0) + k * 3 + row + (0 if side < 0.0 else 7)
				FolkArt.spectator(_stage, Vector2(a.x, a.y), 62.0 * a.z, idx, _cheer if (_g.done or _g.caught) else 0.0)
			var p := _pt(dd, side * 1.2)
			_stage.draw_rect(Rect2(p.x - 2.0 * p.z, p.y - 30.0 * p.z, 4.0 * p.z, 30.0 * p.z), Color("4d3b27"))
		if k % 2 == 0 and dd > 5.0:
			var pa := _pt(dd, -1.2)
			var pb := _pt(dd, 1.2)
			FolkArt.bunting(_stage, Vector2(pa.x, pa.y - 30.0 * pa.z), Vector2(pb.x, pb.y - 30.0 * pb.z), 14.0 * pa.z)
	# things on the hill, far to near
	var things: Array = []
	for o in _g.obstacles:
		var d: float = float(o.y) - _g.y
		if d > -1.6 and d < CheeseRoll.SEE:
			things.append({"d": d, "kind": "o", "o": o})
	things.append({"d": float(_g.cheese.y) - _g.y, "kind": "c"})
	for r in _g.rivals:
		things.append({"d": float(r.y) - _g.y, "kind": "r", "r": r})
	things.sort_custom(func(a, b): return float(a.d) > float(b.d))
	for th in things:
		var d: float = th.d
		if d < -1.6 or d > CheeseRoll.SEE + 30.0:
			continue
		match th.kind:
			"o":
				_draw_obstacle(th.o, d)
			"c":
				var a := _pt(d, float(_g.cheese.x))
				FolkArt.cheese_wheel(_stage, Vector2(a.x, a.y - 22.0 * a.z), maxf(3.0, 26.0 * a.z), float(_g.cheese.spin))
			"r":
				var a := _pt(d, float(th.r.x))
				_draw_runner(Vector2(a.x, a.y), 74.0 * a.z, int(th.r.v < 6.0) * 2, hash(th.r.name) % 7, float(th.r.y) * 0.7, 0.0)
	_draw_player()
	_draw_hud()
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _flash > 0.0:
		_stage.draw_rect(Rect2(0, 0, w, STAGE.y), Color(1, 0.95, 0.8, _flash * 0.6))
	for p in _pops:
		var u := float(p.t) / 1.1
		var col: Color = p.col
		col.a = 1.0 - u * u
		var pos: Vector2 = p.pos + Vector2(-60, -u * 50.0)
		_stage.draw_string(ThemeDB.fallback_font, pos + Vector2(2, 2), str(p.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0, 0, 0, col.a * 0.6))
		_stage.draw_string(ThemeDB.fallback_font, pos, str(p.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)
	if _state == "count":
		var n := ceili(_count)
		var txt := str(n) if n > 0 else "ROLL!"
		_stage.draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 24, 190), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 84, Color("fff2c4"))
	elif _state == "ready":
		_stage.draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 250, 170), "Top of Cooper's Hill", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color("fff2c4"))
		_stage.draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 250, 210), "A Double Gloucester is about to leave without you.", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f0e8cc"))

func _draw_obstacle(o: Dictionary, d: float) -> void:
	var a := _pt(d, float(o.x))
	var s := a.z
	match str(o.kind):
		"tussock":
			_stage.draw_circle(Vector2(a.x, a.y - 6.0 * s), 26.0 * s, Color("46642e"))
			_stage.draw_circle(Vector2(a.x - 5.0 * s, a.y - 12.0 * s), 18.0 * s, Color("5a7d3a"))
			for i in 5:
				_stage.draw_line(Vector2(a.x + (i - 2) * 8.0 * s, a.y - 16.0 * s), Vector2(a.x + (i - 2) * 11.0 * s, a.y - 38.0 * s), Color("6f9446"), maxf(1.0, 3.0 * s))
		"burrow":
			_stage.draw_set_transform(Vector2(a.x, a.y), 0.0, Vector2(1.0, 0.38))
			_stage.draw_circle(Vector2.ZERO, 27.0 * s, Color("7a5f3c"))
			_stage.draw_circle(Vector2.ZERO, 19.0 * s, Color("1d1710"))
			_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if s > 0.45:
				_stage.draw_circle(Vector2(a.x + 4.0 * s, a.y - 8.0 * s), 5.0 * s, Color("c9b79a"))   # a rabbit's ear, mostly
		_:
			_stage.draw_set_transform(Vector2(a.x, a.y), 0.0, Vector2(1.0, 0.3))
			_stage.draw_circle(Vector2.ZERO, 34.0 * s, Color("5f8fa8"))
			_stage.draw_circle(Vector2(-6.0 * s, -4.0 * s), 22.0 * s, Color("86b4c8"))
			_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## A runner seen from behind: legs that scissor with `phase`, a body, head, arms out. mode 2 = stumbling.
func _draw_runner(foot: Vector2, s: float, mode: int, idx: int, phase: float, roll: float) -> void:
	if s < 4.0:
		return
	_stage.draw_set_transform(foot + Vector2(0, -s * 0.45), roll, Vector2.ONE)
	var c := Vector2(0, s * 0.45)    # the foot, relative to the pivot
	var coat: Color = FolkArt.COATS[idx % FolkArt.COATS.size()]
	var skin: Color = FolkArt.SKIN[idx % FolkArt.SKIN.size()]
	var sw := sin(phase) * s * 0.16
	_stage.draw_line(c + Vector2(-s * 0.08, -s * 0.32), c + Vector2(-s * 0.1 + sw, 0), Color("33353f"), maxf(2.0, s * 0.11))
	_stage.draw_line(c + Vector2(s * 0.08, -s * 0.32), c + Vector2(s * 0.1 - sw, 0), Color("33353f"), maxf(2.0, s * 0.11))
	_stage.draw_rect(Rect2(c.x - s * 0.18, c.y - s * 0.7, s * 0.36, s * 0.42), coat)
	var flail := 0.35 if mode == 2 else 0.12
	_stage.draw_line(c + Vector2(-s * 0.18, -s * 0.62), c + Vector2(-s * (0.36 + flail), -s * (0.5 + flail * 0.5) + sw), skin, maxf(2.0, s * 0.08))
	_stage.draw_line(c + Vector2(s * 0.18, -s * 0.62), c + Vector2(s * (0.36 + flail), -s * (0.5 + flail * 0.5) - sw), skin, maxf(2.0, s * 0.08))
	_stage.draw_circle(c + Vector2(0, -s * 0.8), s * 0.16, skin.darkened(0.15))
	_stage.draw_circle(c + Vector2(0, -s * 0.84), s * 0.15, Color("4a3424") if idx % 2 == 0 else Color("c8a060"))   # hair, from behind
	_stage.draw_set_transform(off_xf(), 0.0, Vector2.ONE)

func off_xf() -> Vector2:
	if _shake > 0.0:
		return Vector2(sin(_shake * 90.0), cos(_shake * 70.0)) * 5.0 * (_shake / 0.35)
	return Vector2.ZERO

func _draw_player() -> void:
	var a := _pt(0.0, _g.x)
	var foot := Vector2(a.x, RUN_Y + 40.0)
	_stage.draw_set_transform(foot + Vector2(0, 4), 0.0, Vector2(1.0, 0.25))
	_stage.draw_circle(Vector2.ZERO, 40.0, Color(0, 0, 0, 0.22))
	_stage.draw_set_transform(off_xf(), 0.0, Vector2.ONE)
	if _g.tumble > 0.0:
		var spin := (1.2 - _g.tumble) * 9.0
		_draw_runner(foot + Vector2(0, -20), 130.0, 2, 1, 0.0, spin)
		for i in 3:
			var ang := _cheer * 8.0 + i * 2.1
			_stage.draw_string(ThemeDB.fallback_font, foot + Vector2(cos(ang) * 40.0, -110.0 + sin(ang) * 10.0), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffe27a"))
	else:
		_draw_runner(foot, 140.0, 0, 1, _g.y * 0.9, 0.0)
	# the camber: which way the hill leans just here
	var cam := _g.camber(_g.y + 6.0)
	if absf(cam) > 0.06 and _state == "run":
		var dir := signf(cam)
		var base := Vector2(_sw() * 0.5 + 330.0, STAGE.y - 24.0)
		_stage.draw_line(base - Vector2(dir * 40.0, 0), base + Vector2(dir * 40.0 * clampf(absf(cam) * 3.0, 0.4, 1.0), 0), Color("fff2c4", 0.8), 4.0)
		_stage.draw_string(ThemeDB.fallback_font, base + Vector2(-60, -8), "the slope leans", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff2c4", 0.8))
	if _state == "run" and _g.brace:
		_stage.draw_string(ThemeDB.fallback_font, foot + Vector2(-40, 12), "heels in", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0e8cc"))

func _draw_hud() -> void:
	# a strip down the right: the hill from top to bottom with everyone on it
	var x := _sw() - 34.0
	var top := 40.0
	var h := 250.0
	_stage.draw_rect(Rect2(x - 7, top - 8, 22, h + 16), Color(0.05, 0.07, 0.1, 0.5))
	_stage.draw_line(Vector2(x + 4, top), Vector2(x + 4, top + h), Color("f0e8cc", 0.6), 2.0)
	_stage.draw_rect(Rect2(x - 6, top + h - 2, 20, 4), Color("f4efe0"))
	for r in _g.rivals:
		_stage.draw_circle(Vector2(x + 4, top + h * clampf(float(r.y) / CheeseRoll.LENGTH, 0.0, 1.0)), 5.0, FolkArt.COATS[hash(r.name) % 7])
	_stage.draw_circle(Vector2(x + 4, top + h * clampf(float(_g.cheese.y) / CheeseRoll.LENGTH, 0.0, 1.0)), 6.0, Color("f0c24a"))
	_stage.draw_circle(Vector2(x + 4, top + h * clampf(_g.y / CheeseRoll.LENGTH, 0.0, 1.0)), 7.0, Color("5ab0ff"))
	_stage.draw_arc(Vector2(x + 4, top + h * clampf(_g.y / CheeseRoll.LENGTH, 0.0, 1.0)), 7.0, 0.0, TAU, 12, Color.WHITE, 1.5)
	# speed
	var sp := clampf(_g.v / CheeseRoll.MAX_V, 0.0, 1.0)
	_stage.draw_rect(Rect2(20, STAGE.y - 28, 160, 12), Color(0.05, 0.07, 0.1, 0.55))
	_stage.draw_rect(Rect2(20, STAGE.y - 28, 160 * sp, 12), Color("ffd27a").lerp(Color("ff7a4a"), sp))
	_stage.draw_string(ThemeDB.fallback_font, Vector2(20, STAGE.y - 34), "speed", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0e8cc"))
	# tumbles as plasters
	for i in _g.tumbles:
		_stage.draw_rect(Rect2(20 + i * 22, STAGE.y - 60, 18, 8), Color("e8b890"))
		_stage.draw_rect(Rect2(25 + i * 22, STAGE.y - 60, 8, 8), Color("f4dcc0"))
