extends MenuBase
## Cumberland and Westmorland wrestling (story command {"do": "wrestling"}): the other wrestler telegraphs a throw
## and you answer in time. Left answers a hipe (sink), Up answers a buttock (step round), Right answers a
## cross-buttock (hook the leg), or press the buttons. Best of three falls. Easier play (Settings) gives you a
## longer window and a little more balance. The rules live in Wrestling. Closes with {"won": bool}.
## setup arg: "<venue>:<rival index>" (dev: "dev" shows an exchange under way).

const PAUSE := 1.5
const ACTIONS := {"move_left": "sink", "move_up": "step", "move_right": "hook"}
const GRASS := Color("5f8a43")
const SKY := Color("a9c9dc")
const SKIN := Color("e0b48c")
const VELVET := Color("5a1d3a")
const STITCH := Color("e8c872")
const VEST_ME := Color("f4f1e6")
const VEST_HIM := Color("dde7f0")

var _rng := Rng.new(int(Time.get_ticks_usec()))
var _venue := ""
var _rival: Dictionary = {"who": "A Cumbrian wrestler", "window": 1.4, "feint": 0}
var _easy := false
var _bout := Wrestling.new_bout()
var _fall := Wrestling.new_fall(false)
var _history: Array = []
var _phase := "intro"             # intro | tell | result | over
var _wait := 0.8
var _t := 0.0                     # seconds into this exchange
var _cues: Array = []
var _move := ""
var _win_s := 1.4
var _msg := ""
var _lesson := ""
var _arena: Control
var _info: Label
var _lesson_l: Label
var _buttons: Array = []
var _seen: Dictionary = {}

func _build() -> void:
	set_title("Cumberland and Westmorland wrestling")
	_easy = Settings.easy_darts
	_fall = Wrestling.new_fall(_easy)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	content.add_child(root)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	root.add_child(row)
	_arena = Control.new()
	_arena.custom_minimum_size = Vector2(560, 300)
	_arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.draw.connect(_draw_arena)
	row.add_child(_arena)
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_info)
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 14)
	root.add_child(br)
	for entry in [["sink", "Left: Sink your weight"], ["step", "Up: Step round"], ["hook", "Right: Hook the leg"]]:
		var key: String = entry[0]
		var b := make_button(entry[1], func(): _answer(key), 200)
		br.add_child(b)
		_buttons.append(b)
	_lesson_l = UIKit.label("", 21, UIKit.GOLD)
	_lesson_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_lesson_l)
	_msg = "You lock hold with %s: chest to chest, chin on the right shoulder, arms round the back. First to take the other off his feet wins the fall. Best of three." % _who()
	_refresh()

func setup(arg: String) -> void:
	var p := arg.split(":")
	if arg.begins_with("dev"):
		_rival = {"who": "Big Rob from Egremont", "window": 1.3, "feint": 25}
		_bout = {"me": 1, "opp": 0, "winner": ""}
		_fall = {"me": 2, "opp": 1, "winner": ""}
		_move = "hipe"
		_cues = [{"at": 0.0, "move": "hipe"}]
		_win_s = 99.0
		_t = 0.3
		_phase = "tell"
		_msg = "Fall 2. "
		_refresh()
		return
	_venue = p[0] if p.size() > 0 else ""
	var rivals: Array = Wrestling.venue(_venue).get("rivals", [])
	if not rivals.is_empty():
		_rival = rivals[clampi(int(p[1]) if p.size() > 1 else 0, 0, rivals.size() - 1)]
	_msg = "You lock hold with %s: chest to chest, chin on the right shoulder, arms round the back. First to take the other off his feet wins the fall. Best of three." % _who()
	_refresh()

func _who() -> String:
	return str(_rival.get("who", "your rival")).split(",")[0]

func _process(delta: float) -> void:
	if _phase == "over":
		return
	_wait = maxf(0.0, _wait - delta)
	match _phase:
		"intro", "result":
			if _wait <= 0.0:
				_begin_exchange()
		"tell":
			_t += delta
			for action in ACTIONS:
				if Input.is_action_just_pressed(action):
					_answer(ACTIONS[action])
					return
			if _phase == "tell" and _t > float(_cues.back().at) + _win_s:
				_answer("")
			_arena.queue_redraw()

func _on_cancel() -> void:
	if _phase != "over":
		close({"won": false, "quit": true})

func _begin_exchange() -> void:
	_move = Wrestling.next_move(_rng, _history)
	_history.append(_move)
	_cues = Wrestling.cues(_move, _rng.chance(float(_rival.get("feint", 0))), _rng)
	_win_s = Wrestling.window(float(_rival.get("window", 1.4)), _easy)
	_t = 0.0
	_phase = "tell"
	_lesson = ""
	_refresh()

func _answer(pick: String) -> void:
	if _phase != "tell":
		return
	var res := Wrestling.judge(_cues, pick, _t, _win_s)
	_fall = Wrestling.apply(_fall, res)
	var nm: String = Wrestling.NAMES[_move]
	match res:
		"counter":
			_msg = "Answered! His %s goes nowhere and he is off balance." % nm
			Audio.sfx("confirm")
		"early":
			_msg = "Too soon! That was a feint, and you answered the decoy. His %s catches you." % nm
		"late":
			_msg = "Too slow. His %s lifts you off balance." % nm
		_:
			_msg = "Wrong answer. His %s catches you." % nm
	_lesson = str(Wrestling.LESSONS[_move])
	if _fall.winner != "":
		_msg += " " + ("You throw him! The fall is yours." if _fall.winner == "me" else "Down you go. The fall is his.")
		_bout = Wrestling.record_fall(_bout, str(_fall.winner))
		if _bout.winner != "":
			_finish()
			return
		_fall = Wrestling.new_fall(_easy)
		_history = []
	_phase = "result"
	_wait = PAUSE
	_refresh()
	_arena.queue_redraw()

func _finish() -> void:
	_phase = "over"
	var won: bool = _bout.winner == "me"
	if won:
		_msg += " You take the bout, two falls to %d." % int(_bout.opp)
	else:
		_msg += " %s takes the bout, two falls to %d." % [_who(), int(_bout.me)]
	_refresh()
	await get_tree().create_timer(2.2).timeout
	close({"won": won})

func _refresh() -> void:
	if _info == null:
		return
	var s := "Balance\nYou: %s\n%s: %s\nFalls: you %d, them %d\n\n" % [_pips(int(_fall.me)), _who(), _pips(int(_fall.opp)), int(_bout.me), int(_bout.opp)]
	if _phase == "tell":
		for i in _cues.size():
			if _t >= float(_cues[i].at):
				s += ("" if i == _cues.size() - 1 else "(feint?) ") + Wrestling.tell(str(_cues[i].move)) + "\n"
		if _easy:
			s += "\nIt looks like a %s." % Wrestling.NAMES[_cues.back().move] if _t >= float(_cues.back().at) else ""
	else:
		s += _msg
	_info.text = s
	_lesson_l.text = _lesson if _phase != "tell" else "Read the tell, then answer. If the tell changes, trust the last one."
	set_hints([["confirm", "Answer with the buttons"], ["cancel", "Walk away"]])
	if _arena:
		_arena.queue_redraw()

func _pips(n: int) -> String:
	var out := ""
	for i in maxi(Wrestling.BALANCE + (1 if _easy else 0), n):
		out += "●" if i < n else "○"
	return out

# ---- drawing

func _draw_arena() -> void:
	var sz := _arena.size
	_arena.draw_rect(Rect2(Vector2.ZERO, sz), SKY)
	_arena.draw_rect(Rect2(0, sz.y * 0.62, sz.x, sz.y * 0.38), GRASS)
	_arena.draw_circle(Vector2(sz.x * 0.5, sz.y * 0.84), 150.0, Color(GRASS, 0.0))
	var ground := sz.y * 0.88
	_wrestler(Vector2(sz.x * 0.42, ground), VEST_ME, 0.0, false)
	var lean := 0.0
	var crouch := false
	if _phase == "tell" and not _cues.is_empty():
		var shown := ""
		for c in _cues:
			if _t >= float(c.at):
				shown = str(c.move)
		match shown:
			"hipe":
				crouch = true
			"buttock":
				lean = 0.35
			"cross_buttock":
				lean = -0.3
	_wrestler(Vector2(sz.x * 0.58, ground), VEST_HIM, lean, crouch, true)
	if _phase == "tell":
		var left := clampf(1.0 - maxf(0.0, _t - float(_cues.back().at)) / _win_s, 0.0, 1.0)
		_arena.draw_rect(Rect2(20, 12, (sz.x - 40) * left, 12), STITCH if left > 0.3 else Color("c4463d"))
		_arena.draw_rect(Rect2(20, 12, sz.x - 40, 12), Color.BLACK, false, 2.0)

func _wrestler(base: Vector2, vest: Color, lean: float, crouch: bool, flip := false) -> void:
	var dir := -1.0 if flip else 1.0
	_arena.draw_set_transform(base, lean * dir, Vector2(1.0, 0.86 if crouch else 1.0))
	_arena.draw_rect(Rect2(-22, -70, 18, 70), Color("f0ece0"))      # long johns
	_arena.draw_rect(Rect2(4, -70, 18, 70), Color("f0ece0"))
	_arena.draw_rect(Rect2(-26, -98, 52, 34), VELVET)               # embroidered velvet trunks
	_arena.draw_line(Vector2(-26, -92), Vector2(26, -92), STITCH, 3.0)
	_arena.draw_line(Vector2(-26, -70), Vector2(26, -70), STITCH, 3.0)
	_arena.draw_rect(Rect2(-26, -168, 52, 72), vest)                # vest
	_arena.draw_circle(Vector2(30.0 * dir, -186), 20.0, SKIN)        # head, chin over the other's shoulder
	_arena.draw_line(Vector2(-24, -150), Vector2(60.0 * dir, -136), SKIN, 12.0)  # arm round the back
	_arena.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
