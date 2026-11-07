extends MenuBase
## Pub darts (story command {"do": "darts"}): 501 against a local, double to finish. A reticle wobbles slowly around
## your aim point; move the aim with the direction keys and press Confirm to throw. Easier darts (Settings) steadies
## the wobble and shows the checkout. The numbers live in Darts. Closes with {"won": bool} (null if you walk out).
## setup arg: "<nation>:<pub>:<rung index>" (dev: "dev" shows a leg under way).

const BOARD_PX := 420.0
const AIM_SPEED := 0.55           # board radii per second
const PAUSE := 1.1                # seconds the local's visit stays on screen
const MAX_TURNS := 30
const RING_A := Color("1c1c1c")
const RING_B := Color("e8dcb0")
const RING_RED := Color("b83a32")
const RING_GREEN := Color("2f7d4a")

var _rng := Rng.new(int(Time.get_ticks_usec()))
var _nation := ""
var _pub := ""
var _rung := 0
var _rival: Dictionary = {}
var _mine := Darts.START
var _theirs := Darts.START
var _before := Darts.START      # my score at the start of this visit
var _thrown: Array = []         # this visit's darts, newest last
var _turns := 0
var _aim := Vector2(0.0, -0.6)  # treble 20 area
var _t := 0.0
var _wait := 0.5                # seconds until input is live
var _busy := false
var _over := false
var _msg := "Move the aim, then press Confirm to throw."
var _steady: Dictionary
var _board: Control
var _reticle: Control
var _info: Label
var _hint_l: Label
var _darts_marks: Array = []    # board points of this visit's darts

func _build() -> void:
	set_title("Darts")
	_steady = Darts.steadiness(Settings.easy_darts)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(BOARD_PX + 20.0, BOARD_PX + 20.0)
	root.add_child(holder)
	_board = Control.new()
	_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.draw.connect(_draw_board)
	holder.add_child(_board)
	_reticle = Control.new()
	_reticle.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.draw.connect(_draw_reticle)
	holder.add_child(_reticle)
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
	set_hints([["confirm", "Throw"], ["cancel", "Walk away"]])
	_refresh()

func setup(arg: String) -> void:
	var p := arg.split(":")
	_nation = p[0] if p.size() > 0 else ""
	_pub = p[1] if p.size() > 1 else ""
	_rung = int(p[2]) if p.size() > 2 else 0
	var rungs: Array = Darts.league(_nation).get("rungs", [])
	_rival = rungs[clampi(_rung, 0, rungs.size() - 1)] if not rungs.is_empty() else {"who": "A local", "sigma": 0.25}
	if arg.begins_with("dev"):
		_rival = {"who": "Maureen from the Tram Shelter", "sigma": 0.25}
		_mine = 261
		_theirs = 140
	_refresh()

func _process(delta: float) -> void:
	if _over:
		return
	_t += delta
	_wait = maxf(0.0, _wait - delta)
	if _busy or _wait > 0.0:
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v != Vector2.ZERO:
		_aim = (_aim + v * AIM_SPEED * delta).limit_length(1.05)
	_reticle.queue_redraw()
	if Input.is_action_just_pressed("confirm"):
		_throw()

func _on_cancel() -> void:
	if _over or _busy:
		return
	close({"won": false, "quit": true})

func _reticle_pos() -> Vector2:
	return Darts.reticle(_aim, _t, float(_steady.wobble), float(_steady.speed))

func _throw() -> void:
	var at := _reticle_pos()
	var s := Darts.score_at(at)
	_thrown.append(s)
	_darts_marks.append(at)
	Audio.sfx("confirm" if int(s.points) >= 40 else "cursor")
	var res := Darts.throw_dart(_mine, int(s.points), int(s.mult))
	if res.bust:
		_msg = "%s. Bust! Score back to %d." % [s.label, _before]
		_mine = _before
		await _end_visit()
	elif res.won:
		_mine = 0
		_msg = "%s. Game shot!" % s.label
		_finish(true)
	else:
		_mine = int(res.remaining)
		_msg = "%s (%d)." % [s.label, int(s.points)]
		if _thrown.size() >= 3:
			await _end_visit()
	_refresh()

func _end_visit() -> void:
	_busy = true
	_refresh()
	await get_tree().create_timer(PAUSE).timeout
	_turns += 1
	if _turns >= MAX_TURNS:
		_finish(_mine <= _theirs)
		return
	var v := Darts.local_visit(_theirs, float(_rival.get("sigma", 0.25)), _rng)
	var names := (v.thrown as Array).map(func(d): return str(d.label))
	_theirs = int(v.remaining)
	_msg = "%s throws %s%s." % [_who(), ", ".join(names), ". Bust" if v.bust else ""]
	if v.won:
		_msg = "%s throws %s. Game shot, and not to you." % [_who(), ", ".join(names)]
		_theirs = 0
		_refresh()
		_finish(false)
		return
	_refresh()
	await get_tree().create_timer(PAUSE * 1.5).timeout
	_thrown = []
	_darts_marks = []
	_before = _mine
	_busy = false
	_wait = 0.2
	_refresh()

func _finish(won: bool) -> void:
	_over = true
	_refresh()
	await get_tree().create_timer(1.4).timeout
	var top := (Darts.league(_nation).get("rungs", []) as Array).size() - 1
	await PiecePrompt.after_game(self, "darts", (2.0 if _rung >= top else 1.0) if won else 0.0)
	close({"won": won})

func _who() -> String:
	return str(_rival.get("who", "The local"))

func _refresh() -> void:
	if _info == null:
		return
	_info.text = "You: %d\n%s: %d\n\n%s" % [_mine, _who(), _theirs, _msg]
	var route := Darts.checkout(_mine)
	var left := 3 - _thrown.size()
	_hint_l.text = ("Checkout: " + " ".join(PackedStringArray(route))) if Settings.easy_darts and not route.is_empty() and route.size() <= left else ""
	_board.queue_redraw()
	_reticle.queue_redraw()

# ---- drawing (board units to pixels: the board's centre is the middle of the holder)

func _px(p: Vector2) -> Vector2:
	return _board.size * 0.5 + p * (BOARD_PX * 0.5)

func _wedge(r0: float, r1: float, a0: float, a1: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 4
	for i in steps + 1:
		var a := lerpf(a0, a1, float(i) / steps)
		pts.append(_px(Vector2(sin(a), -cos(a)) * r1))
	for i in steps + 1:
		var a := lerpf(a1, a0, float(i) / steps)
		pts.append(_px(Vector2(sin(a), -cos(a)) * r0))
	_board.draw_colored_polygon(pts, col)

func _draw_board() -> void:
	var c := _board.size * 0.5
	_board.draw_circle(c, BOARD_PX * 0.5 + 14.0, Color("14110f"))
	for i in 20:
		var a0 := deg_to_rad(float(i) * 18.0 - 9.0)
		var a1 := deg_to_rad(float(i) * 18.0 + 9.0)
		var dark := i % 2 == 0
		var plain := RING_A if dark else RING_B
		var ring := RING_RED if dark else RING_GREEN
		_wedge(Darts.OUTER_BULL, Darts.TREBLE_IN, a0, a1, plain)
		_wedge(Darts.TREBLE_IN, Darts.TREBLE_OUT, a0, a1, ring)
		_wedge(Darts.TREBLE_OUT, Darts.DOUBLE_IN, a0, a1, plain)
		_wedge(Darts.DOUBLE_IN, 1.0, a0, a1, ring)
		var lp := _px(Vector2(sin((a0 + a1) * 0.5), -cos((a0 + a1) * 0.5)) * 1.08)
		_board.draw_string(ThemeDB.fallback_font, lp - Vector2(10, -7), str(Darts.ORDER[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.CREAM)
	_board.draw_circle(c, Darts.OUTER_BULL * BOARD_PX * 0.5, RING_GREEN)
	_board.draw_circle(c, Darts.BULL * BOARD_PX * 0.5, RING_RED)
	for m in _darts_marks:
		_board.draw_circle(_px(m), 4.0, Color("f4e3a1"))
		_board.draw_arc(_px(m), 4.0, 0.0, TAU, 12, Color.BLACK, 1.5)

func _draw_reticle() -> void:
	if _over or _busy:
		return
	var p := _px(_reticle_pos())
	var col := Color("ffffff")
	_reticle.draw_arc(p, 11.0, 0.0, TAU, 24, col, 2.5)
	_reticle.draw_line(p + Vector2(-17, 0), p + Vector2(-6, 0), col, 2.5)
	_reticle.draw_line(p + Vector2(6, 0), p + Vector2(17, 0), col, 2.5)
	_reticle.draw_line(p + Vector2(0, -17), p + Vector2(0, -6), col, 2.5)
	_reticle.draw_line(p + Vector2(0, 6), p + Vector2(0, 17), col, 2.5)
	# the aim point itself, small and steady, so you can see what you are steering
	_reticle.draw_circle(_px(_aim), 3.0, Color("e8c872"))
