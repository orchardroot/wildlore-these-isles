extends MenuBase
## Curling (story command {"do": "curling"}): a four-stone end against a club skip. For each of your stones, choose
## the weight (Left/Right), then the line (Left/Right moves the broom, Up/Down changes the handle) and press
## Confirm; then tap Confirm to sweep while the stone slides. The skip throws theirs in between, and you have the
## last stone. The numbers live in Curling. Closes with {"won": bool} (null if you walk out).
## setup arg: "<rink>:<skip index>" (dev: "dev" shows an end part way through).

const PX_PER_M := 78.0
const Y_MIN := -9.4               # metres shown: from just past the hog line to just behind the back line
const Y_MAX := 2.9
const SLIDE_SECONDS := 4.2
const COAST_SECONDS := 0.8
const PAUSE := 1.2
const LINE_STEP := 0.25
const BROOM_MAX := 2.0
const ICE := Color("e6f2f8")
const BLUE := Color("4a78b8")
const RED := Color("c4463d")
const WHITE := Color("f7fbfd")
const MINE := Color("e6c23a")
const THEIRS := Color("c4463d")

var _rng := Rng.new(int(Time.get_ticks_usec()))
var _rink := ""
var _rung := 0
var _skip: Dictionary = {"who": "The club skip", "sigma_w": 0.8, "sigma_l": 0.3, "hit": 50}
var _stones: Array = []
var _thrown := 0
var _phase := "weight"            # weight | line | slide | coast | wait | over
var _weight := 6
var _broom := 0.0
var _handle := 1
var _taps := 0
var _t := 0.0
var _wait := 0.4
var _ice := 0.0
var _easy := false
var _msg := ""
var _slide: Dictionary = {}       # the stone in flight: {team, dist, broom, handle, taps, result}
var _board: Control
var _info: Label
var _lesson: Label
var _seen: Dictionary = {}        # lessons already given this end

func _build() -> void:
	set_title("Curling")
	_easy = Settings.easy_darts
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	content.add_child(root)
	_board = Control.new()
	_board.custom_minimum_size = Vector2(Y_MAX * 0.0 + (Y_MAX - Y_MIN) * PX_PER_M, 2.0 * Curling.HALF_SHEET * PX_PER_M)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.draw.connect(_draw_board)
	root.add_child(_board)
	_info = UIKit.label("", 22, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	_lesson = UIKit.label("", 21, UIKit.GOLD)
	_lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_lesson)
	_new_end()
	_refresh()

func setup(arg: String) -> void:
	var p := arg.split(":")
	if arg.begins_with("dev"):
		_skip = {"who": "Mrs Fraser, skip for forty winters", "sigma_w": 0.5, "sigma_l": 0.22, "hit": 75}
		_stones = [{"team": 1, "x": 0.35, "y": -0.2}, {"team": 0, "x": -0.4, "y": 0.45}, {"team": 1, "x": -0.6, "y": -3.6}, {"team": 0, "x": 0.9, "y": -1.1}]
		_thrown = 5
		_msg = "Your stone is in the house."
		_phase = "line" if arg == "dev:line" else "weight"
		_weight = 5
		_broom = -0.5
		_refresh()
		return
	_rink = p[0] if p.size() > 0 else ""
	_rung = int(p[1]) if p.size() > 1 else 0
	var skips: Array = Curling.rink(_rink).get("skips", [])
	if not skips.is_empty():
		_skip = skips[clampi(_rung, 0, skips.size() - 1)]
	_new_end()
	_refresh()

func _new_end() -> void:
	_stones = []
	_thrown = 0
	_ice = Curling.ice_speed(_rng)
	_msg = "%s %s" % [_who(), Curling.ice_name(_ice)]
	_phase = "wait"
	_wait = 0.6

func _who() -> String:
	return str(_skip.get("who", "The skip"))

func _my_turn() -> bool:
	return _thrown % 2 == 1

func _process(delta: float) -> void:
	if _phase == "over":
		return
	_t += delta
	_wait = maxf(0.0, _wait - delta)
	match _phase:
		"wait":
			if _wait <= 0.0 and _thrown < Curling.STONES_EACH * 2:
				if _my_turn():
					_phase = "weight"
					_refresh()
				else:
					_skip_throw()
			elif _wait <= 0.0:
				_finish()
		"weight":
			if _wait > 0.0:
				return
			if Input.is_action_just_pressed("move_left"):
				_weight = maxi(1, _weight - 1)
				Audio.sfx("cursor")
				_refresh()
			elif Input.is_action_just_pressed("move_right"):
				_weight = mini(10, _weight + 1)
				Audio.sfx("cursor")
				_refresh()
			elif Input.is_action_just_pressed("confirm"):
				_phase = "line"
				_wait = 0.15
				Audio.sfx("confirm")
				_refresh()
		"line":
			if _wait > 0.0:
				return
			if Input.is_action_just_pressed("move_left"):
				_broom = maxf(-BROOM_MAX, _broom - LINE_STEP)
				_refresh()
			elif Input.is_action_just_pressed("move_right"):
				_broom = minf(BROOM_MAX, _broom + LINE_STEP)
				_refresh()
			elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
				_handle = -_handle
				Audio.sfx("cursor")
				_refresh()
			elif Input.is_action_just_pressed("confirm"):
				_begin_slide(0, Curling.weight_distance(_weight), _broom, _handle)
		"slide":
			if Input.is_action_just_pressed("confirm") and _my_turn_slide():
				_taps += 1
				Audio.sfx("cursor")
			_slide.u = minf(1.0, float(_slide.u) + delta / SLIDE_SECONDS)
			if float(_slide.u) >= 1.0:
				_end_slide()
			_board.queue_redraw()
		"coast":
			_slide.v = minf(1.0, float(_slide.v) + delta / COAST_SECONDS)
			if float(_slide.v) >= 1.0:
				_land()
			_board.queue_redraw()

func _my_turn_slide() -> bool:
	return int(_slide.team) == 0

func _on_cancel() -> void:
	if _phase == "over":
		return
	if _phase == "line":
		_phase = "weight"
		_refresh()
		return
	if _phase in ["weight", "wait"]:
		close({"won": false, "quit": true})

func _begin_slide(team: int, dist: float, broom: float, handle: int) -> void:
	_taps = 0
	_slide = {"team": team, "dist": dist, "broom": broom, "handle": handle, "u": 0.0, "v": 0.0}
	_phase = "slide"
	Audio.sfx("confirm")
	_refresh()

func _end_slide() -> void:
	var taps := _taps if int(_slide.team) == 0 else 0
	var res := Curling.deliver(_stones, int(_slide.team), float(_slide.dist), float(_slide.broom), int(_slide.handle), taps, _ice, _easy)
	_slide.result = res
	_slide.taps = taps
	_phase = "coast"
	_refresh()

func _land() -> void:
	var res: Dictionary = _slide.result
	_stones = res.stones
	_thrown += 1
	var mine := int(_slide.team) == 0
	_msg = "%s %s" % ["You:" if mine else _who() + ":", _describe(str(res.event), res, mine)]
	if mine and int(_slide.taps) == 0 and str(res.event) in ["hog", "guard"]:
		_lesson.text = "Tap Confirm while the stone slides to sweep it further."
	_slide = {}
	_phase = "wait"
	_wait = PAUSE
	_refresh()

func _describe(event: String, res: Dictionary, mine: bool) -> String:
	var who := "your stone" if mine else "their stone"
	match event:
		"hog":
			_teach("hog", "The hog line: a stone has to get past the far one or it is taken off. Throw harder, or sweep.")
			return "Short of the hog line, taken off."
		"back":
			_teach("back", "Over the back line is out too. Lighter next time, and don't sweep a heavy one.")
			return "Through the house and over the back line, out."
		"wide":
			return "Off the side of the sheet, out."
		"hit":
			_teach("hit", "A take-out: a heavy stone in the line of another knocks it off the sheet.")
			return "Hit and knocked a stone out."
		"glance":
			return "A glancing blow. The stone is moved but still there."
		"guard":
			_teach("guard", "A guard sits in front of the house. It blocks a clear path and shelters what is behind it.")
			return "A guard in front of the house."
		_:
			var d := Vector2(float(res.x), float(res.y)).length()
			if d <= Curling.BUTTON + Curling.STONE_R:
				_teach("button", "The button is the centre. The stone nearest it is the shot stone.")
				return "On the button!"
			_teach("house", "In the house. At the end only stones in the rings count.")
			return "%s is in the house." % who.capitalize()
	return ""

func _teach(key: String, text: String) -> void:
	if _seen.has(key):
		return
	_seen[key] = true
	_lesson.text = text

func _skip_throw() -> void:
	var a := Curling.skip_stone(_stones, 1, _skip, _ice, _rng)
	_msg = "%s throws a %s." % [_who(), "take-out" if a.kind == "takeout" else "draw"]
	_begin_slide(1, float(a.dist), float(a.broom), int(a.handle))

func _finish() -> void:
	_phase = "over"
	var sc := Curling.score_end(_stones)
	var won := int(sc.team) == 0
	if sc.team == -1:
		_msg = "A blank end. Nothing in the house to score."
	elif won:
		_msg = "You score %d! The end is yours." % int(sc.points)
	else:
		_msg = "%s scores %d." % [_who(), int(sc.points)]
	_refresh()
	await get_tree().create_timer(2.0).timeout
	close({"won": won})

func _refresh() -> void:
	if _info == null:
		return
	var left_me := Curling.STONES_EACH - _thrown / 2
	var left_them := Curling.STONES_EACH - (_thrown + 1) / 2
	var s := "Stones left: you %d, %s %d.  %s" % [left_me, _who().split(",")[0], left_them, _msg]
	if _phase == "weight":
		s += "\nWeight %d: %s. Left and Right to change, Confirm to set it." % [_weight, Curling.weight_name(_weight)]
	elif _phase == "line":
		s += "\nBroom %+.2f m, handle: %s. Left and Right move the broom, Up or Down turns the handle. The stone curls towards the handle side, about a metre." % [_broom, "in" if _handle > 0 else "out"]
	elif _phase == "slide" and int(_slide.get("team", 1)) == 0:
		s += "\nSWEEP! Tap Confirm."
	_info.text = s
	set_hints(_hints())
	_board.queue_redraw()

func _hints() -> Array:
	match _phase:
		"weight":
			return [["confirm", "Set weight"], ["cancel", "Walk away"]]
		"line":
			return [["confirm", "Throw"], ["cancel", "Back"]]
		"slide":
			return [["confirm", "Sweep"]]
	return []

# ---- drawing (metres to pixels: y runs left to right, x across the sheet)

func _px(x: float, y: float) -> Vector2:
	return Vector2((y - Y_MIN) * PX_PER_M, _board.size.y * 0.5 + x * PX_PER_M)

func _circle_at(r: float, col: Color) -> void:
	_board.draw_circle(_px(0.0, 0.0), r * PX_PER_M, col)

func _draw_board() -> void:
	var sz := _board.size
	_board.draw_rect(Rect2(Vector2.ZERO, sz), ICE)
	_board.draw_rect(Rect2(Vector2.ZERO, sz), Color("2b3a4d"), false, 4.0)
	_circle_at(Curling.HOUSE, BLUE)
	_circle_at(1.22, WHITE)
	_circle_at(0.61, RED)
	_circle_at(Curling.BUTTON, WHITE)
	var line := Color("30465e")
	_board.draw_line(_px(-Curling.HALF_SHEET, 0.0), _px(Curling.HALF_SHEET, 0.0), line, 2.0)      # tee line
	_board.draw_line(_px(0.0, Y_MIN), _px(0.0, Y_MAX), line, 1.5)                                  # centre line
	_board.draw_line(_px(-Curling.HALF_SHEET, Curling.HOG), _px(Curling.HALF_SHEET, Curling.HOG), RED, 4.0)
	_board.draw_line(_px(-Curling.HALF_SHEET, Curling.BACK), _px(Curling.HALF_SHEET, Curling.BACK), line, 2.0)
	var f := ThemeDB.fallback_font
	_board.draw_string(f, _px(-Curling.HALF_SHEET, Curling.HOG) + Vector2(6, 20), "hog line", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("7a2a26"))
	_board.draw_string(f, _px(-Curling.HALF_SHEET, 0.0) + Vector2(6, 20), "tee line", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, line)
	if _phase == "line":
		var ghost := Curling.deliver([], 0, Curling.weight_distance(_weight), _broom, _handle, 0, _ice if _easy else 0.0, _easy)
		var broom_p := _px(_broom, Curling.weight_distance(_weight) - Curling.HACK_TO_TEE)
		_board.draw_line(_px(_broom, Y_MIN), broom_p, Color(0.2, 0.2, 0.2, 0.35), 2.0)
		_board.draw_circle(broom_p, 5.0, Color("5a3a1a"))
		if str(ghost.event) in ["house", "guard"]:
			_board.draw_arc(_px(float(ghost.x), float(ghost.y)), 11.0, 0.0, TAU, 20, Color(0.1, 0.1, 0.1, 0.5), 2.0)
	for s in _stones:
		_draw_stone(_px(float(s.x), float(s.y)), MINE if int(s.team) == 0 else THEIRS)
	if not _slide.is_empty():
		var p := _slide_pos()
		_draw_stone(p, MINE if int(_slide.team) == 0 else THEIRS)

func _slide_pos() -> Vector2:
	var dist := float(_slide.dist)
	if _phase == "coast":
		var res: Dictionary = _slide.result
		var from := _slide_point(dist, 1.0)
		return from.lerp(_px(float(res.x), float(res.y)), float(_slide.v))
	var u := float(_slide.u)
	return _slide_point(dist, 1.0 - (1.0 - u) * (1.0 - u))

func _slide_point(dist: float, frac: float) -> Vector2:
	var d_total := dist + _ice
	var curl := Curling._curl(d_total, 0)
	var travelled := d_total * frac
	var x := Curling.lateral(float(_slide.broom), int(_slide.handle), curl, travelled / d_total)
	return _px(x, travelled - Curling.HACK_TO_TEE)

func _draw_stone(p: Vector2, col: Color) -> void:
	var r := Curling.STONE_R * PX_PER_M * 1.15
	_board.draw_circle(p, r, Color("6c6c72"))
	_board.draw_circle(p, r * 0.72, col)
	_board.draw_arc(p, r, 0.0, TAU, 18, Color.BLACK, 1.5)
