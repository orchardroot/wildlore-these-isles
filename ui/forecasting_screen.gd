extends MenuBase
## The forecaster's chart challenge (story command {"do": "forecast"}): a synoptic chart on the left (isobars round
## a low or a high, a front, a compass, Britain and Ireland), two questions per chart on the right (the wind, then
## the sky), a line of explanation after each answer, then the score. Three practice charts and today's (see
## Forecasting). Closes with {"score", "total", "today": bool (today's chart read right)}, or null if the player
## walks out. setup arg: "forecasting:<weather>" for today's chart; "dev" (seed 7, a gale) and "dev:answered"
## (the first question already answered, wrongly) for screenshots.

const CORRECT_BG := Color("2f5d3a")
const CORRECT_EDGE := Color("8fd19e")
const WRONG_BG := Color("6b2c2c")
const WRONG_EDGE := Color("e08a8a")
const LETTERS := ["A", "B", "C", "D"]

var _rng: Rng
var _round: Array = []      # [{chart, questions, today}]
var _chart_i := 0
var _q_i := 0
var _score := 0
var _today_right := 0       # right answers on today's chart
var _picked := -1
var _view: ChartView
var _side: VBoxContainer
var _buttons: Array = []
var _question_panel: Control

## Draws one chart. Everything is in fractions of the box so it fits whatever size it is given.
class ChartView extends Control:
	const SEA := Color("27384a")
	const LAND := Color("5e7a4c")
	const LAND_EDGE := Color("a9c08f")
	const GRID := Color("ffffff14")
	const ISOBAR := Color("f4ecd2")
	const WARM := Color("e05a5a")
	const COLD := Color("5a8ee0")
	const INK := Color("f8f1dc")
	const BRITAIN := Vector2(0.5, 0.52)
	## Where each bearing puts the pressure centre, as a direction from Britain.
	const DIRS := {"north": Vector2(0, -1), "north-east": Vector2(0.7, -0.7), "east": Vector2(1, 0), "south-east": Vector2(0.7, 0.7),
		"south": Vector2(0, 1), "south-west": Vector2(-0.7, 0.7), "west": Vector2(-1, 0), "north-west": Vector2(-0.7, -0.7)}
	const STEP := {"tight": 0.055, "moderate": 0.1, "loose": 0.16}
	## Rough outlines, as fractions of the box (y down).
	const GB := [Vector2(0.55, 0.14), Vector2(0.60, 0.14), Vector2(0.62, 0.26), Vector2(0.55, 0.36), Vector2(0.60, 0.44),
		Vector2(0.66, 0.54), Vector2(0.74, 0.62), Vector2(0.70, 0.68), Vector2(0.74, 0.73), Vector2(0.62, 0.78), Vector2(0.52, 0.78),
		Vector2(0.36, 0.84), Vector2(0.46, 0.74), Vector2(0.38, 0.72), Vector2(0.42, 0.64), Vector2(0.42, 0.58), Vector2(0.48, 0.58),
		Vector2(0.46, 0.50), Vector2(0.46, 0.44), Vector2(0.40, 0.42), Vector2(0.44, 0.36), Vector2(0.38, 0.40), Vector2(0.40, 0.30),
		Vector2(0.38, 0.22), Vector2(0.44, 0.12)]
	const IE := [Vector2(0.22, 0.38), Vector2(0.28, 0.40), Vector2(0.30, 0.48), Vector2(0.26, 0.56), Vector2(0.28, 0.64),
		Vector2(0.18, 0.68), Vector2(0.08, 0.60), Vector2(0.08, 0.50), Vector2(0.12, 0.42), Vector2(0.16, 0.36)]

	var chart: Dictionary = {}

	func _ready() -> void:
		clip_contents = true

	func _px(f: Vector2) -> Vector2:
		return Vector2(f.x * size.x, f.y * size.y)

	func _poly(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(_px(p))
		return out

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), SEA)
		for i in range(1, 6):
			draw_line(Vector2(size.x * i / 6.0, 0), Vector2(size.x * i / 6.0, size.y), GRID, 1.0)
			draw_line(Vector2(0, size.y * i / 6.0), Vector2(size.x, size.y * i / 6.0), GRID, 1.0)
		for land in [GB, IE]:
			var p := _poly(land)
			draw_colored_polygon(p, LAND)
			p.append(p[0])
			draw_polyline(p, LAND_EDGE, 2.0)
		var font := get_theme_default_font()
		draw_string(font, Vector2(14, 30), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
		draw_line(Vector2(22, 36), Vector2(22, 64), INK, 2.0)
		draw_line(Vector2(22, 36), Vector2(16, 46), INK, 2.0)
		draw_line(Vector2(22, 36), Vector2(28, 46), INK, 2.0)
		if chart.is_empty():
			return
		var scale := minf(size.x, size.y)
		var bearing := str(chart.get("bearing", "over"))
		var dir: Vector2 = DIRS.get(bearing, Vector2.ZERO)
		var centre: Vector2 = BRITAIN + Vector2(0, -0.03) if bearing == "over" else BRITAIN + dir * 0.4
		var c := _px(centre)
		var low := str(chart.get("centre", "low")) == "low"
		var step := float(STEP.get(str(chart.get("spacing", "moderate")), 0.1)) * scale
		var p0 := int(chart.get("pressure", 1000))
		for k in range(1, 6):
			var r := step * k
			draw_arc(c, r, 0.0, TAU, 96, ISOBAR, 1.5 if k > 1 else 2.0)
			if k % 2 == 1:  # every other ring is labelled, up the diagonal so tight rings don't overlap
				var label := str(p0 + (4 * k if low else -4 * k))
				draw_string(font, c + Vector2(r * 0.72 + 6, -r * 0.72 - 2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ISOBAR)
		draw_string(font, c + Vector2(-13, 14), "L" if low else "H", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, WARM if low else COLD)
		draw_string(font, c + Vector2(-22, 34), str(p0), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
		var front := str(chart.get("front", "none"))
		if low and front != "none":
			_front(c, _px(BRITAIN), front == "warm")
		var b := _px(BRITAIN)
		draw_circle(b, 5.0, INK)
		draw_string(font, b + Vector2(10, 6), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
		draw_string(font, Vector2(14, size.y - 14), "Isobars every 4 millibars", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ISOBAR)

	## A front sweeping from the low past Britain: red with bumps (warm), blue with teeth (cold).
	func _front(c: Vector2, b: Vector2, warm: bool) -> void:
		var col := WARM if warm else COLD
		var away := (b - c).normalized()
		var side := Vector2(-away.y, away.x)
		var pts := PackedVector2Array()
		var n := 24
		for i in range(0, n + 1):
			var t := float(i) / n
			var p := c.lerp(b + away * 180.0, t) + side * sin(t * PI) * 70.0
			pts.append(p)
		draw_polyline(pts, col, 4.0)
		for i in range(4, n, 5):
			var p: Vector2 = pts[i]
			var dir: Vector2 = (pts[i + 1] - pts[i - 1]).normalized()
			var out := Vector2(dir.y, -dir.x)  # the side the front is moving towards
			if warm:
				draw_circle(p + out * 2.0, 7.0, col)
			else:
				draw_colored_polygon(PackedVector2Array([p - dir * 7.0, p + dir * 7.0, p + out * 12.0]), col)

func _build() -> void:
	set_title("Reading the chart")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 20)
	content.add_child(row)
	var frame := UIKit.panel(Color("1d2230f0"), 8)
	frame.custom_minimum_size = Vector2(540, 0)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(frame)
	_view = ChartView.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(_view)
	_side = VBoxContainer.new()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.add_theme_constant_override("separation", 10)
	row.add_child(_side)
	_begin("clear", Rng.new(int(Time.get_ticks_usec())))

func setup(arg: String) -> void:
	var parts := arg.split(":")
	var dev := parts.size() > 0 and parts[0] == "dev"
	var weather := "gale" if dev else (parts[0] if parts.size() > 0 and parts[0] != "" else "clear")
	_begin(weather, Rng.new(7) if dev else Rng.new(int(Time.get_ticks_usec())))
	if dev and parts.size() > 1 and parts[1] == "answered":
		var q: Dictionary = _round[0].questions[0]
		_answer(0 if int(q.answer) != 0 else 1)

func _begin(weather: String, rng: Rng) -> void:
	_rng = rng
	_round = Forecasting.build_round(rng, weather)
	_chart_i = 0
	_q_i = 0
	_score = 0
	_today_right = 0
	if _round.is_empty():
		closed.emit(null)
		return
	_ask()

# ---- asking

func _entry() -> Dictionary:
	return _round[_chart_i]

func _question() -> Dictionary:
	return _entry().questions[_q_i]

func _ask() -> void:
	_picked = -1
	_reset()
	var e := _entry()
	_view.chart = e.chart
	_view.queue_redraw()
	_update_header()
	set_hints([["updown", "Choose"], ["confirm", "Answer"], ["cancel", "Walk out"]])
	_side.add_child(_chart_panel(e))
	var q := _question()
	_question_panel = _question_box(q)
	_side.add_child(_question_panel)
	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 6)
	_side.add_child(opts)
	for i in q.options.size():
		var b := Button.new()
		b.text = "%s    %s" % [LETTERS[i], _pretty(str(q.options[i]))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 38)
		b.add_theme_font_size_override("font_size", 22)
		b.focus_entered.connect(func(): Audio.sfx("cursor"))
		b.pressed.connect(_answer.bind(i))
		opts.add_child(b)
		_buttons.append(b)
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])

func _chart_panel(e: Dictionary) -> Control:
	var p := UIKit.panel(Color("1d2230f0"), 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var c: Dictionary = e.chart
	var head := ("TODAY'S CHART" if bool(e.today) else "CHART %d OF %d" % [_chart_i + 1, _round.size()])
	v.add_child(UIKit.label(head, 18, UIKit.HEATHER.lightened(0.3)))
	var t := UIKit.label(str(c.get("title", "")), 26)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var season := str(c.get("season", "any"))
	var syn := UIKit.label("The general synopsis: %s.%s" % [Forecasting.synopsis(c), ("  Season: %s." % season) if season != "any" else ""], 18, Color("d8cfb4"))
	syn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(syn)
	return p

func _question_box(q: Dictionary) -> Control:
	var p := UIKit.panel(Color("1d2230f0"), 12)
	var l := UIKit.label(str(q.q), 26)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p

## "south-westerly" -> "South-westerly", "light and variable" -> "Light and variable"; weather names come ready.
func _pretty(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)

func _answer(i: int) -> void:
	if _picked >= 0:
		return
	_picked = i
	var q := _question()
	var right: bool = i == int(q.answer)
	if right:
		_score += 1
		if bool(_entry().today):
			_today_right += 1
	Audio.sfx("heal" if right else "bump")
	_update_header()
	for k in _buttons.size():
		var b: Button = _buttons[k]
		b.focus_mode = Control.FOCUS_NONE
		if k == int(q.answer):
			_tint(b, CORRECT_BG, CORRECT_EDGE)
		elif k == i:
			_tint(b, WRONG_BG, WRONG_EDGE)
	# the explanation takes the question's place, so the column fits whatever the chart
	if _question_panel != null:
		_question_panel.queue_free()
		_question_panel = null
	var fb := UIKit.panel(Color("1d2230f0"), 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	fb.add_child(v)
	var head := "Right." if right else "Not quite: %s." % _pretty(str(q.options[q.answer]))
	v.add_child(UIKit.label(head, 24, CORRECT_EDGE if right else WRONG_EDGE))
	var why := UIKit.label(str(q.why), 18, Color("d8cfb4"))
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(why)
	_side.add_child(fb)
	_side.move_child(fb, 1)
	var last: bool = _chart_i + 1 >= _round.size() and _q_i + 1 >= _entry().questions.size()
	var next := make_button("See your score" if last else "Next chart" if _q_i + 1 >= _entry().questions.size() else "Next question", _next, 220)
	next.custom_minimum_size = Vector2(220, 42)
	next.add_theme_font_size_override("font_size", 24)
	_side.add_child(next)
	_side.move_child(next, 2)  # under the explanation, above the tinted options, so it is never off the bottom
	set_hints([["confirm", "Carry on"], ["cancel", "Walk out"]])
	UIKit.focus_later(next)

func _tint(b: Button, bg: Color, edge: Color) -> void:
	var s := UIKit.box(bg, edge, 2, 6, 10)
	for state in ["normal", "hover", "focus", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, s)
	b.add_theme_color_override("font_color", Color("ffffff"))

func _next() -> void:
	_q_i += 1
	if _q_i >= _entry().questions.size():
		_q_i = 0
		_chart_i += 1
	if _chart_i >= _round.size():
		_show_result()
	else:
		_ask()

# ---- the score

func _total() -> int:
	var n := 0
	for e in _round:
		n += e.questions.size()
	return n

func _show_result() -> void:
	_reset()
	header_right.text = ""
	var p := UIKit.panel(Color("1d2230f0"), 28)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var big := UIKit.label("%d / %d" % [_score, _total()], 96, UIKit.GOLD)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(big)
	var line := UIKit.label(Forecasting.reaction(_score, _total()), 24)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(line)
	var done := make_button("Hand in your forecast", _finish, 320)
	done.add_theme_font_size_override("font_size", 26)
	var row := CenterContainer.new()
	row.add_child(done)
	v.add_child(row)
	set_hints([["confirm", "Done"]])
	UIKit.focus_later(done)

func _finish() -> void:
	if _done:
		return
	await PiecePrompt.after_game(self, "forecasting", 100.0 * _score / maxf(1.0, float(_total())))
	_done = true  # not close(): that plays the back-out sound
	closed.emit({"score": _score, "total": _total(), "today": _today_right >= Forecasting.PER_CHART})

# ---- shared bits

func _reset() -> void:
	UIKit.clear(_side)
	_buttons.clear()

func _update_header() -> void:
	header_right.text = "Score %d of %d" % [_score, _total()]

func _on_cancel() -> void:
	close(null)
