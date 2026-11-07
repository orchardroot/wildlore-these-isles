extends MenuBase
## The gurning contest (story command {"do": "gurn"}): Egremont Crab Fair, Cumbria. Put your head through the braffin
## (the horse collar). The judges flash a gurn at a time; copy the run back with the direction keys (up, right, down,
## left, each its own face and its own note), and every round adds one. Two slips and the collar comes off (three, a
## slower show and no time limit with Easier minigames). Your score is the longest run copied cleanly. The numbers
## live in Gurning. Closes with {"won": bool, "draw": bool, "best": int} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a round under way).

const STAGE := Vector2(1040, 360)
const NOTES := [1.0, 1.26, 0.84, 1.5]
const SKIN := Color("e3b48c")
const DIRS := ["move_up", "move_right", "move_down", "move_left"]

var _venue_id := "egremont"
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _seq: Array = []
var _phase := "intro"          # intro, show, input, pause, over
var _timer := 1.0
var _show_i := 0
var _in_i := 0
var _slips := 0
var _best := 0
var _their := -1
var _face := -1                # the face on show right now (-1 = resting)
var _mirror := 0.0             # seconds the player's own face stays up
var _flash := Color(0, 0, 0, 0)
var _cheer := 0.0
var _clock := 0.0
var _left := 0.0
var _easy := false
var _msg := "Collar on. Watch the judges, then copy them."
var _stage: Control
var _info: Label

func _build() -> void:
	set_title("The gurning contest")
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
	set_hints([["move_up", "Cross-eyed"], ["move_right", "Lip"], ["move_down", "Chin"], ["move_left", "Teeth"], ["cancel", "Walk away"]])
	_rival = Gurning.venue(_venue_id).rival
	_seq = Gurning.start_sequence(_rng)
	_refresh()

func setup(arg: String) -> void:
	_venue_id = arg if not Gurning.venue(arg).is_empty() else "egremont"
	_rival = Gurning.venue(_venue_id).rival
	if arg.begins_with("dev"):
		_seq = Gurning.start_sequence(Rng.new(7))
		_seq = Gurning.extend(_seq, Rng.new(8))
		_best = 3
		_slips = 1
		_phase = "show"
		_show_i = 2
		_timer = 0.3
		_face = int(_seq[2])
		_msg = "Round 2. Watch closely."
	_refresh()

func _on_cancel() -> void:
	if _phase == "over":
		return
	close(null)

func _process(delta: float) -> void:
	_clock += delta
	_cheer = maxf(0.0, _cheer - delta)
	_mirror = maxf(0.0, _mirror - delta)
	_flash.a = maxf(0.0, _flash.a - delta * 2.0)
	_stage.queue_redraw()
	match _phase:
		"intro", "pause":
			_timer -= delta
			if _timer <= 0.0:
				_begin_show()
		"show":
			_timer -= delta
			if _timer <= 0.0:
				if _face >= 0:
					_face = -1
					_timer = 0.16
				else:
					_show_i += 1
					if _show_i >= _seq.size():
						_phase = "input"
						_in_i = 0
						_left = Gurning.answer_time(_easy)
						_msg = "Your turn: copy them in order (%d faces)." % _seq.size()
						Audio.sfx("cursor")
						_refresh()
					else:
						_show_face(_show_i)
		"input":
			if _left > 0.0 or Gurning.answer_time(_easy) > 0.0:
				if Gurning.answer_time(_easy) > 0.0:
					_left -= delta
					if _left <= 0.0:
						_slip(-1)
						return
			for d in 4:
				if Input.is_action_just_pressed(DIRS[d]):
					_answer(Gurning.face_for_dir(["up", "right", "down", "left"][d]))
					break

func _begin_show() -> void:
	_phase = "show"
	_show_i = 0
	_msg = "Round %d: watch the judges." % (_seq.size() - Gurning.START_LEN + 1)
	_show_face(0)
	_refresh()

func _show_face(i: int) -> void:
	_face = int(_seq[i])
	_timer = Gurning.show_time(_seq.size(), _easy)
	Audio.sfx_at("cursor", 0.0, NOTES[_face])

func _answer(f: int) -> void:
	_face = f
	_mirror = 0.4
	if Gurning.is_correct(_seq, _in_i, f):
		Audio.sfx_at("cursor", 0.0, NOTES[f])
		_in_i += 1
		_left = Gurning.answer_time(_easy)
		if _in_i >= _seq.size():
			_best = maxi(_best, _seq.size())
			_cheer = 1.2
			_flash = Color(0.9, 0.8, 0.4, 0.45)
			Audio.sfx("level_up")
			_msg = "Clean run of %d! One more face to come." % _seq.size()
			_seq = Gurning.extend(_seq, _rng)
			_phase = "pause"
			_timer = 1.5
		else:
			_msg = "%d of %d." % [_in_i, _seq.size()]
		_refresh()
	else:
		_slip(f)

func _slip(f: int) -> void:
	_slips += 1
	_flash = Color(0.8, 0.2, 0.2, 0.5)
	Audio.sfx("bump")
	var want: String = str(Gurning.faces()[int(_seq[_in_i])].name)
	var why := "Too slow." if f < 0 else "Wrong face."
	if _slips > Gurning.slips_allowed(_easy):
		_finish("%s That one was %s. The collar comes off." % [why, want])
		return
	_msg = "%s That one was %s. Watch again." % [why, want]
	_phase = "pause"
	_timer = 1.8
	_refresh()

func _finish(why: String) -> void:
	_phase = "over"
	_their = Gurning.local_best(_rival, _rng)
	var who := str(_rival.get("who", "The champion")).split(",")[0]
	_msg = "%s\n\nYour longest run: %d. %s manages %d. %s" % [why, _best, who, _their, Gurning.advice(_best)]
	_refresh()
	await get_tree().create_timer(2.4).timeout
	await PiecePrompt.after_game(self, Gurning.GAME_ID, float(_best))
	close({"won": _best > _their, "draw": _best == _their, "best": _best})

func _refresh() -> void:
	if _info == null:
		return
	var who := str(_rival.get("who", "The champion")).split(",")[0]
	var slips_left := maxi(0, Gurning.slips_allowed(_easy) - _slips + 1)
	_info.text = "Longest run: %d.   Slips left: %d.   Against %s.\n%s" % [_best, slips_left, who, _msg]
	_stage.queue_redraw()

# ---- drawing

func _draw_stage() -> void:
	var w := STAGE.x
	var h := STAGE.y
	var s := _stage
	# evening sky in bands, with Lakeland fells behind the fair
	var bands := [Color("f4c98a"), Color("f0b27a"), Color("d99a8e"), Color("a98aa8"), Color("6f6fa0")]
	for i in bands.size():
		s.draw_rect(Rect2(0, h * 0.0 + i * 46.0, w, 48.0), bands[bands.size() - 1 - i])
	s.draw_circle(Vector2(w * 0.82, 120), 38.0, Color("fbe3a8"))
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, 210), Vector2(120, 140), Vector2(210, 180), Vector2(330, 110), Vector2(470, 190), Vector2(600, 130), Vector2(760, 200), Vector2(900, 120), Vector2(w, 180), Vector2(w, 260), Vector2(0, 260)]), Color("6b6a94"))
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, 240), Vector2(160, 190), Vector2(300, 230), Vector2(520, 180), Vector2(700, 235), Vector2(880, 190), Vector2(w, 235), Vector2(w, 280), Vector2(0, 280)]), Color("4d5a7a"))
	# the marquee roof and bunting
	s.draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5 - 430, 96), Vector2(w * 0.5, 14), Vector2(w * 0.5 + 430, 96)]), Color("a23b3b"))
	for k in 12:
		var x0 := w * 0.5 - 430.0 + k * 72.0
		s.draw_colored_polygon(PackedVector2Array([Vector2(x0, 96), Vector2(x0 + 36, 96), Vector2(x0 + 18, 14 + (1.0 - absf(x0 + 18 - w * 0.5) / 430.0) * 0.0 + 70)]) if false else PackedVector2Array([Vector2(x0, 96), Vector2(x0 + 36, 96), Vector2(x0 + 18, 70)]), Color("c9514b") if k % 2 == 0 else Color("e8d8b0"))
	s.draw_rect(Rect2(w * 0.5 - 430, 96, 860, 10), Color("7a2a2a"))
	for k in 24:
		var bx := 20.0 + k * 44.0
		var by := 124.0 + sin(k * 0.52) * 7.0
		var col := [Color("d95f4a"), Color("e8c872"), Color("5fa3c4"), Color("8fbf6a")][k % 4]
		s.draw_colored_polygon(PackedVector2Array([Vector2(bx, by), Vector2(bx + 28, by), Vector2(bx + 14, by + 24)]), col)
	s.draw_line(Vector2(0, 124), Vector2(w, 124), Color("3a2c28"), 2.0)
	# the stage boards, the judges' table and a crowd that bobs when you do well
	s.draw_rect(Rect2(0, 262, w, h - 262), Color("6b4a32"))
	for k in 20:
		s.draw_line(Vector2(k * 56.0, 262), Vector2(k * 56.0 - 30, h), Color("4e3524"), 2.0)
	s.draw_rect(Rect2(34, 228, 190, 60), Color("8a6a4a"))
	s.draw_rect(Rect2(34, 224, 190, 8), Color("b08a60"))
	s.draw_rect(Rect2(52, 196, 70, 30), Color("f2e8cf"))
	s.draw_string(ThemeDB.fallback_font, Vector2(60, 218), "JUDGES", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("3a2c28"))
	for k in 3:
		var jx := 70.0 + k * 52.0
		s.draw_circle(Vector2(jx, 188), 14.0, SKIN)
		s.draw_rect(Rect2(jx - 14, 200, 28, 20), [Color("3a5a7a"), Color("5a3a5a"), Color("3a5a4a")][k])
	var crowd_cols := [Color("2d3347"), Color("4a2d3a"), Color("2d4a3f"), Color("574a2d"), Color("3a2d57")]
	for k in 17:
		var cx := 18.0 + k * 62.0
		var bob := sin(_clock * 6.0 + k) * 5.0 * (1.0 if _cheer > 0.0 else 0.0) - (7.0 if _cheer > 0.0 else 0.0)
		var cy := h - 26.0 + (k % 3) * 4.0 + bob
		s.draw_rect(Rect2(cx - 20, cy, 40, 40), crowd_cols[k % 5])
		s.draw_circle(Vector2(cx, cy - 8), 15.0, SKIN.darkened(0.12 * (k % 4)))
		if _cheer > 0.0:
			s.draw_line(Vector2(cx - 18, cy + 4), Vector2(cx - 26, cy - 22), SKIN, 5.0)
			s.draw_line(Vector2(cx + 18, cy + 4), Vector2(cx + 26, cy - 22), SKIN, 5.0)
	# the gurner and the braffin
	var c := Vector2(w * 0.5, 190.0)
	var shown := _face
	var label := ""
	if _phase == "show" and _face >= 0:
		label = str(Gurning.faces()[_face].name)
	elif _mirror > 0.0 and _face >= 0:
		label = str(Gurning.faces()[_face].name)
	if _phase == "input" and _mirror <= 0.0:
		shown = -1
	s.draw_rect(Rect2(c.x - 70, c.y + 62, 140, 90), Color("3a4a6a"))
	s.draw_circle(c + Vector2(0, 8), 82.0, Color("7a4a2c"))
	_draw_face(c, 62.0, shown)
	_draw_collar(c)
	# four arrows round the collar: each direction is a face
	_draw_pad(Vector2(c.x, 38), 0, "up")
	_draw_pad(Vector2(c.x + 190, c.y), 1, "right")
	_draw_pad(Vector2(c.x, h - 6 - 36 - 14), 2, "down")
	_draw_pad(Vector2(c.x - 190, c.y), 3, "left")
	if label != "":
		var tw := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		s.draw_rect(Rect2(c.x - tw * 0.5 - 14, 276, tw + 28, 38), Color(0.1, 0.08, 0.1, 0.78))
		s.draw_string(ThemeDB.fallback_font, Vector2(c.x - tw * 0.5, 304), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIKit.GOLD)
	# progress pips for the run, and slips
	var n := _seq.size()
	for i in n:
		var px := w - 30.0 - (n - i) * 26.0
		var done := (_phase == "input" and i < _in_i) or (_phase == "show" and i < _show_i) or _phase == "pause" and false
		s.draw_circle(Vector2(px, 28), 9.0, UIKit.GOLD if done else Color(1, 1, 1, 0.25))
	for i in Gurning.slips_allowed(_easy):
		var used := i < _slips
		s.draw_arc(Vector2(40 + i * 34, 28), 11.0, PI * 0.1, PI * 0.9, 8, Color("d9a0a0") if used else UIKit.CREAM, 5.0)
	if _flash.a > 0.0:
		s.draw_rect(Rect2(0, 0, w, h), _flash)
	if _phase == "input" and Gurning.answer_time(_easy) > 0.0:
		var frac := clampf(_left / Gurning.answer_time(_easy), 0.0, 1.0)
		s.draw_rect(Rect2(c.x - 100, 6, 200, 8), Color(0, 0, 0, 0.4))
		s.draw_rect(Rect2(c.x - 100, 6, 200 * frac, 8), UIKit.GOLD if frac > 0.3 else Color("d9604a"))

func _draw_pad(p: Vector2, face: int, dir: String) -> void:
	var on := _face == face and (_phase == "show" or _mirror > 0.0)
	var r := Rect2(p - Vector2(74, 22), Vector2(148, 44))
	_stage.draw_rect(r, Color("f2e8cf") if on else Color(0.1, 0.1, 0.16, 0.7))
	_stage.draw_rect(r, UIKit.GOLD, false, 2.0)
	var arrow := {"up": "^", "right": ">", "down": "v", "left": "<"}[dir]
	var nm: String = str(Gurning.faces()[face].name).replace("The ", "")
	_stage.draw_string(ThemeDB.fallback_font, p + Vector2(-66, 8), arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("3a2c28") if on else UIKit.GOLD)
	_stage.draw_string(ThemeDB.fallback_font, p + Vector2(-44, 7), nm, HORIZONTAL_ALIGNMENT_LEFT, 112, 16, Color("3a2c28") if on else UIKit.CREAM)

## The horse collar, drawn over the neck of the face: a thick leather ring with brass studs and a red lining.
func _draw_collar(c: Vector2) -> void:
	var s := _stage
	s.draw_arc(c + Vector2(0, 8), 82.0, 0.0, TAU, 40, Color("3a2418"), 16.0)
	s.draw_arc(c + Vector2(0, 8), 70.0, 0.0, TAU, 40, Color("8a2b2b"), 5.0)
	for k in 12:
		var a := TAU * k / 12.0
		s.draw_circle(c + Vector2(0, 8) + Vector2(cos(a), sin(a)) * 86.0, 3.5, Color("e8c872"))
	s.draw_rect(Rect2(c.x - 8, c.y - 96, 16, 20), Color("b8923a"))   # the hames, standing up above

func _draw_face(c: Vector2, r: float, kind: int) -> void:
	var s := _stage
	s.draw_circle(c - Vector2(r * 0.95, 0), r * 0.2, SKIN.darkened(0.08))
	s.draw_circle(c + Vector2(r * 0.95, 0), r * 0.2, SKIN.darkened(0.08))
	s.draw_circle(c, r, SKIN)
	s.draw_arc(c + Vector2(0, -r * 0.85), r * 0.5, PI, TAU, 10, Color("6b4a2a"), 6.0)   # a sparse comb-over
	var ey := c.y - r * 0.2
	var ex := r * 0.38
	var brow := Color("5a3a22")
	match kind:
		0:   # cross-eyed, brows high
			s.draw_line(Vector2(c.x - ex - 14, ey - 30), Vector2(c.x - ex + 14, ey - 38), brow, 5.0)
			s.draw_line(Vector2(c.x + ex - 14, ey - 38), Vector2(c.x + ex + 14, ey - 30), brow, 5.0)
			for sgn in [-1.0, 1.0]:
				s.draw_circle(Vector2(c.x + sgn * ex, ey), 13.0, Color("fdfaf0"))
				s.draw_circle(Vector2(c.x + sgn * ex - sgn * 7.0, ey + 2), 5.5, Color("1a1a24"))
			s.draw_circle(Vector2(c.x, c.y + r * 0.45), 7.0, Color("5a2a2a"))
		1:   # top lip reaching up over the nose
			s.draw_line(Vector2(c.x - ex - 14, ey - 18), Vector2(c.x - ex + 14, ey - 22), brow, 5.0)
			s.draw_line(Vector2(c.x + ex - 14, ey - 22), Vector2(c.x + ex + 14, ey - 18), brow, 5.0)
			for sgn in [-1.0, 1.0]:
				s.draw_circle(Vector2(c.x + sgn * ex, ey), 11.0, Color("fdfaf0"))
				s.draw_circle(Vector2(c.x + sgn * ex, ey + 1), 4.5, Color("1a1a24"))
			s.draw_circle(Vector2(c.x, c.y + r * 0.1), 7.0, SKIN.darkened(0.15))
			s.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 34, c.y + r * 0.55), Vector2(c.x - 26, c.y + 2), Vector2(c.x, c.y - 4), Vector2(c.x + 26, c.y + 2), Vector2(c.x + 34, c.y + r * 0.55)]), Color("b86a6a"))
			s.draw_line(Vector2(c.x - 26, c.y + r * 0.55), Vector2(c.x + 26, c.y + r * 0.55), Color("5a2a2a"), 4.0)
		2:   # jutting chin, low brows, squint
			s.draw_line(Vector2(c.x - ex - 14, ey - 14), Vector2(c.x - ex + 14, ey - 6), brow, 6.0)
			s.draw_line(Vector2(c.x + ex - 14, ey - 6), Vector2(c.x + ex + 14, ey - 14), brow, 6.0)
			for sgn in [-1.0, 1.0]:
				s.draw_line(Vector2(c.x + sgn * ex - 10, ey + 2), Vector2(c.x + sgn * ex + 10, ey + 2), Color("1a1a24"), 4.0)
			s.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 30, c.y + r * 0.4), Vector2(c.x + 30, c.y + r * 0.4), Vector2(c.x + 26, c.y + r * 1.0), Vector2(c.x - 26, c.y + r * 1.0)]), SKIN.darkened(0.06))
			s.draw_line(Vector2(c.x - 24, c.y + r * 0.45), Vector2(c.x + 24, c.y + r * 0.45), Color("5a2a2a"), 4.0)
			s.draw_rect(Rect2(c.x - 20, c.y + r * 0.46, 40, 9), Color("b86a6a"))
		3:   # wide toothless grin
			s.draw_line(Vector2(c.x - ex - 14, ey - 24), Vector2(c.x - ex + 14, ey - 28), brow, 5.0)
			s.draw_line(Vector2(c.x + ex - 14, ey - 28), Vector2(c.x + ex + 14, ey - 24), brow, 5.0)
			for sgn in [-1.0, 1.0]:
				s.draw_circle(Vector2(c.x + sgn * ex, ey), 14.0, Color("fdfaf0"))
				s.draw_circle(Vector2(c.x + sgn * ex, ey), 6.0, Color("1a1a24"))
			s.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 40, c.y + r * 0.3), Vector2(c.x + 40, c.y + r * 0.3), Vector2(c.x + 28, c.y + r * 0.62), Vector2(c.x - 28, c.y + r * 0.62)]), Color("4a1c1c"))
			s.draw_rect(Rect2(c.x - 3, c.y + r * 0.3, 7, 11), Color("fdfaf0"))   # the one tooth left
		_:   # at rest
			for sgn in [-1.0, 1.0]:
				s.draw_circle(Vector2(c.x + sgn * ex, ey), 11.0, Color("fdfaf0"))
				s.draw_circle(Vector2(c.x + sgn * ex, ey), 4.5, Color("1a1a24"))
			s.draw_line(Vector2(c.x - 18, c.y + r * 0.45), Vector2(c.x + 18, c.y + r * 0.45), Color("5a2a2a"), 3.0)
	if kind != 1:
		s.draw_circle(Vector2(c.x, c.y + r * 0.1), 7.0, SKIN.darkened(0.15))
