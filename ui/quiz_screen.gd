extends MenuBase
## The pub quiz (story command {"do": "quiz"}): five multiple-choice questions, a fact after each answer, then the score.
## Closes with {"score": n, "total": n}, or null if the player walks out. The prize is handled by the command.
## setup arg: "<pub id>:<region>"; dev/screenshot arg adds ":answered" to show a question already answered (wrongly);
## "<pub id>:<region>::final" is the cup final (QuizLeague.final_size() questions).

const CORRECT_BG := Color("2f5d3a")
const CORRECT_EDGE := Color("8fd19e")
const WRONG_BG := Color("6b2c2c")
const WRONG_EDGE := Color("e08a8a")
const LETTERS := ["A", "B", "C", "D"]

var _rng: Rng
var _questions: Array = []   # built questions: {q, options, answer, fact, cat}
var _index := 0
var _score := 0
var _picked := -1            # option chosen on this question, -1 while still asking
var _root: VBoxContainer
var _buttons: Array = []

func _build() -> void:
	set_title("Pub quiz")
	_root = VBoxContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_constant_override("separation", 10)
	content.add_child(_root)
	_begin("all", Rng.new(int(Time.get_ticks_usec())))

func setup(arg: String) -> void:
	var parts := arg.split(":")
	var region := parts[1] if parts.size() > 1 and parts[1] != "" else "all"
	var dev := parts.size() > 2 and parts[2] == "answered"
	var size := QuizLeague.final_size() if parts.size() > 3 and parts[3] == "final" else PubQuiz.ROUND_SIZE
	_begin(region, Rng.new(7) if dev else Rng.new(int(Time.get_ticks_usec())), size)
	if dev:
		_answer(0 if _questions[0].answer != 0 else 1)

func _begin(region: String, rng: Rng, size := PubQuiz.ROUND_SIZE) -> void:
	_rng = rng
	_questions = []
	for q in PubQuiz.pick_round(PubQuiz.load_bank(), region, rng, size):
		_questions.append(PubQuiz.build(q, rng))
	_index = 0
	_score = 0
	_ask()

# ---- asking

func _ask() -> void:
	_picked = -1
	var q: Dictionary = _questions[_index]
	_reset()
	_update_header()
	set_hints([["updown", "Choose"], ["confirm", "Answer"], ["cancel", "Walk out"]])
	_root.add_child(_question_panel(q))
	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 8)
	_root.add_child(opts)
	for i in q.options.size():
		var b := Button.new()
		b.text = "%s    %s" % [LETTERS[i], q.options[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 54)
		b.add_theme_font_size_override("font_size", 28)
		b.focus_entered.connect(func(): Audio.sfx("cursor"))
		b.pressed.connect(_answer.bind(i))
		opts.add_child(b)
		_buttons.append(b)
	UIKit.wrap_focus(_buttons)
	UIKit.focus_later(_buttons[0])

func _question_panel(q: Dictionary) -> Control:
	var p := UIKit.panel(Color("1d2230f0"), 14)
	p.custom_minimum_size = Vector2(0, 112)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(UIKit.label(str(q.cat).to_upper(), 20, UIKit.HEATHER.lightened(0.3)))
	var l := UIKit.label(q.q, 34)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(l)
	return p

func _answer(i: int) -> void:
	if _picked >= 0:
		return
	_picked = i
	var q: Dictionary = _questions[_index]
	var right: bool = i == int(q.answer)
	if right:
		_score += 1
	Audio.sfx("heal" if right else "bump")
	_update_header()
	for k in _buttons.size():
		var b: Button = _buttons[k]
		b.focus_mode = Control.FOCUS_NONE
		if k == int(q.answer):
			_tint(b, CORRECT_BG, CORRECT_EDGE)
		elif k == i:
			_tint(b, WRONG_BG, WRONG_EDGE)
	var fb := UIKit.panel(Color("1d2230f0"), 14)
	fb.custom_minimum_size = Vector2(0, 104)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	fb.add_child(v)
	var head := "Correct!" if right else "Not quite. It was %s." % q.options[q.answer]
	v.add_child(UIKit.label(head, 28, CORRECT_EDGE if right else WRONG_EDGE))
	var f := UIKit.label(q.fact, 24, Color("d8cfb4"))
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(f)
	_root.add_child(fb)
	var last := _index + 1 >= _questions.size()
	var next := make_button("See your score" if last else "Next question", _next, 280)
	next.custom_minimum_size = Vector2(280, 46)
	next.add_theme_font_size_override("font_size", 28)
	_root.add_child(next)
	set_hints([["confirm", "Carry on"], ["cancel", "Walk out"]])
	UIKit.focus_later(next)

func _tint(b: Button, bg: Color, edge: Color) -> void:
	var s := UIKit.box(bg, edge, 2, 6, 10)
	for state in ["normal", "hover", "focus", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, s)
	b.add_theme_color_override("font_color", Color("ffffff"))

func _next() -> void:
	_index += 1
	if _index >= _questions.size():
		_show_result()
	else:
		_ask()

# ---- the score

func _show_result() -> void:
	_reset()
	header_right.text = ""
	var total := _questions.size()
	var p := UIKit.panel(Color("1d2230f0"), 28)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var big := UIKit.label("%d / %d" % [_score, total], 96, UIKit.GOLD)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(big)
	var line := UIKit.label(PubQuiz.reaction(_score, total), 28)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(line)
	var done := make_button("Hand in your answers", _finish, 360)
	done.add_theme_font_size_override("font_size", 28)
	var row := CenterContainer.new()
	row.add_child(done)
	v.add_child(row)
	set_hints([["confirm", "Done"]])
	UIKit.focus_later(done)

func _finish() -> void:
	if _done:
		return
	await PiecePrompt.after_game(self, "quiz", 100.0 * _score / maxf(1.0, float(_questions.size())))
	_done = true  # not close(): that plays the back-out sound
	closed.emit({"score": _score, "total": _questions.size()})

# ---- shared bits

func _reset() -> void:
	UIKit.clear(_root)
	_buttons.clear()

func _update_header() -> void:
	header_right.text = "Question %d of %d  ·  Score %d" % [_index + 1, _questions.size(), _score]

func _on_cancel() -> void:
	close(null)
