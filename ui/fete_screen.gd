extends MenuBase
## The village fete (see Fete). One screen, three events chosen by the setup arg ("cheese", "bog", "welly"; add
## ":dev" for a game under way):
##   cheese  left/right to match each lurch of the hill as it comes, then hold Confirm to dive over the line
##   bog     Confirm to kick on the beat, Up for the breaths marked "B"
##   welly   Confirm stops the power meter, then the angle; three throws, best counts
## Easier minigames (Settings) widens the timings and slows the meters. Closes with {"won": bool, "summary": String}
## ({"quit": true} too if you walk out).

const SKY := Color("9fc7dc")
const GRASS := Color("4c8a45")
const PEAT := Color("4a3626")
const GOLD := Color("e8c45a")
const GOOD := Color("6fbf73")
const BAD := Color("c46a6a")
const CREAM := Color("f4ecd0")

var _kind := "cheese"
var _e: Dictionary
var _easy := false
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _t := 0.0
var _over := false
var _msg := ""
var _stage: Control
var _info: Label
var _result: Dictionary = {}
var _dev := false
var _since := 0.0
# cheese
var _course: Array = []
var _gate := 0
var _stumbles := 0
var _hold := 0.0
var _dive_started := false
var _rivals: Array = []
const GATE_FIRST := 1.8
const GATE_GAP := 1.5
# bog
var _pattern: Array = []
var _bbeat: Dictionary
var _next_beat := 0
var _misses := 0
var _flash := 0.0
# welly
var _phase := 0            # 0 power, 1 angle, 2 flying
var _power := 0.0
var _angle := 45.0
var _throw := 0
var _best := 0.0
var _last := 0.0
var _wind := 0.0
var _pause := 0.0
var _lock_t := 0.0

func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(900, 330)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Go"], ["cancel", "Walk away"]])
	_refresh()

func setup(arg: String) -> void:
	var p := arg.split(":")
	_kind = p[0] if p.size() > 0 and Fete.EVENTS.has(p[0]) else "cheese"
	_dev = "dev" in p
	_e = Fete.event(_kind)
	_easy = Settings.easy_darts
	set_title(str(_e.get("name", "Fete")))
	match _kind:
		"cheese":
			_course = Fete.cheese_course(_rng)
			_rivals = Fete.cheese_rivals(_rng, _easy)
			if _dev:
				_gate = 3
				_t = GATE_FIRST + 3.0 * GATE_GAP - 0.4
		"bog":
			_pattern = Fete.bog_pattern(_rng)
			_bbeat = Fete.bog_beat(_easy)
			if _dev:
				_next_beat = 6
				_misses = 1
				_t = 1.0 + 6.0 * float(_bbeat.interval) - 0.3
		"welly":
			_wind = Fete.wind(_rng)
			if _dev:
				_throw = 1
				_best = 27.4
				_last = 27.4
	_refresh()

func _process(delta: float) -> void:
	if _over or _e.is_empty():
		return
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	match _kind:
		"cheese":
			_process_cheese(delta)
		"bog":
			_process_bog()
		_:
			_process_welly(delta)
	_stage.queue_redraw()
	_since += delta
	if _since > 0.2:
		_since = 0.0
		_refresh()

# ---- cheese

func _gate_time(i: int) -> float:
	return GATE_FIRST + float(i) * GATE_GAP

func _process_cheese(delta: float) -> void:
	var win_s := 0.8 if _easy else 0.5
	if _gate < Fete.GATES:
		var offset := _t - _gate_time(_gate)
		var lean := 0
		if Input.is_action_just_pressed("move_left"):
			lean = -1
		elif Input.is_action_just_pressed("move_right"):
			lean = 1
		if lean != 0 and offset > -win_s - 0.3:
			if Fete.cheese_judge(lean, int(_course[_gate]), offset, _easy):
				_msg = "Steady."
				Audio.sfx("cursor")
			else:
				_stumble()
			_gate += 1
		elif offset > win_s:
			_stumble()
			_gate += 1
		return
	# the last stretch: hold Confirm to dive
	var end := _gate_time(Fete.GATES) + 0.3
	if _t < end:
		return
	if Input.is_action_pressed("confirm"):
		_hold += delta
		_dive_started = true
	if _t >= end + 1.4:
		_finish_cheese()

func _stumble() -> void:
	_stumbles += 1
	_flash = 0.3
	_msg = "Stumble!"
	Audio.sfx("deny")

func _finish_cheese() -> void:
	var dived := Fete.dive_ok(_hold, _easy)
	var mine := Fete.cheese_time(_stumbles, dived)
	var pl := Fete.place(mine, _rivals)
	var s := "You finish in %.1f seconds, place %d of 4 (%d stumbles%s)." % [mine, pl, _stumbles, ", dived" if dived else ", no dive"]
	_msg = s
	_finish(pl == 1, s)

# ---- bog

func _process_bog() -> void:
	var itv := float(_bbeat.interval)
	var window := float(_bbeat.window)
	if _next_beat >= _pattern.size():
		_finish_bog()
		return
	var bt := 1.0 + float(_next_beat) * itv
	var kick := Input.is_action_just_pressed("confirm")
	var breath := Input.is_action_just_pressed("move_up")
	if kick or breath:
		if absf(_t - bt) <= window + 0.1:
			var right: bool = (kick and _pattern[_next_beat] == "k") or (breath and _pattern[_next_beat] == "b")
			if right:
				_msg = "Good."
				Audio.sfx("cursor")
			else:
				_miss("Wrong one.")
			_next_beat += 1
	elif _t > bt + window:
		_miss("Missed it.")
		_next_beat += 1

func _miss(m: String) -> void:
	_misses += 1
	_flash = 0.3
	_msg = m
	Audio.sfx("deny")

func _finish_bog() -> void:
	var tm := Fete.bog_time(_misses)
	var s := "Your time: %d:%04.1f (%d slips), to beat %d:%02d." % [int(tm) / 60, fmod(tm, 60.0), _misses, int(Fete.BOG_TARGET) / 60, int(Fete.BOG_TARGET) % 60]
	_msg = s
	_finish(tm <= Fete.BOG_TARGET, s)

# ---- welly

func _process_welly(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		if _pause <= 0.0:
			if _throw >= Fete.WELLY_THROWS:
				var s := "Best throw %.1f m, you need %.0f m." % [_best, Fete.WELLY_TARGET]
				_finish(_best >= Fete.WELLY_TARGET, s)
			else:
				_phase = 0
				_lock_t = _t
				_wind = Fete.wind(_rng)
		return
	var slow := 1.5 if _easy else 1.0
	if _phase == 0:
		_power = Fete.sweep(_t - _lock_t, 1.6 * slow)
	elif _phase == 1:
		_angle = 10.0 + 70.0 * Fete.sweep(_t - _lock_t, 2.0 * slow)
	if Input.is_action_just_pressed("confirm"):
		if _phase == 0:
			_phase = 1
			_lock_t = _t
		elif _phase == 1:
			_phase = 2
			_last = Fete.welly_distance(_power, _angle, _wind)
			_best = maxf(_best, _last)
			_throw += 1
			_msg = "%.1f metres." % _last
			Audio.sfx("item" if _last >= Fete.WELLY_TARGET else "cursor")
			_pause = 1.6

func _finish(won: bool, summary: String) -> void:
	_over = true
	_result = {"won": won, "summary": summary}
	_msg = summary + "  " + ("Well done." if won else "Not this time.")
	_refresh()
	get_tree().create_timer(1.8).timeout.connect(func(): close(_result))

func _on_cancel() -> void:
	if _over:
		return
	close({"won": false, "quit": true})

func _refresh() -> void:
	if _info == null or _e.is_empty():
		return
	var head := ""
	match _kind:
		"cheese":
			head = "Left or right to match each lurch when the arrow reaches the line. Gate %d of %d. Hold Confirm for the last stretch." % [mini(_gate + 1, Fete.GATES), Fete.GATES]
		"bog":
			head = "Confirm to kick on the ring, Up for a breath (B). Beat %d of %d, slips %d." % [mini(_next_beat + 1, _pattern.size()), _pattern.size(), _misses]
		_:
			var step := "Confirm to stop the power." if _phase == 0 else "Confirm to stop the angle." if _phase == 1 else ""
			head = "Throw %d of %d. Wind %+.1f (positive is behind you). Best %.1f m of %.0f. %s" % [mini(_throw + 1, Fete.WELLY_THROWS), Fete.WELLY_THROWS, _wind, _best, Fete.WELLY_TARGET, step]
	_info.text = head + "\n" + _msg

# ---- drawing

func _draw_stage() -> void:
	if _e.is_empty():
		return
	var s := _stage.size
	_stage.draw_rect(Rect2(0, 0, s.x, s.y), SKY)
	match _kind:
		"cheese":
			_draw_cheese(s)
		"bog":
			_draw_bog(s)
		_:
			_draw_welly(s)

func _draw_cheese(s: Vector2) -> void:
	# the hill: a steep slope from top left to bottom right, the cheese bowling down it
	var top := Vector2(60, 70)
	var bot := Vector2(s.x - 60, s.y - 60)
	_stage.draw_colored_polygon(PackedVector2Array([top, bot, Vector2(top.x, bot.y)]), GRASS)
	var span := _gate_time(Fete.GATES) + 0.3
	var f := clampf(_t / (span + 1.4), 0.0, 1.0)
	var cheese := top.lerp(bot, f)
	_stage.draw_circle(cheese + Vector2(0, -12), 12.0, GOLD)
	var me := top.lerp(bot, clampf(f - 0.04, 0.0, 1.0)) + Vector2(-16 if _flash <= 0.0 else -4, -24)
	_stage.draw_circle(me, 10.0, BAD if _flash > 0.0 else CREAM)
	# the lurch arrow for the next gate
	if _gate < Fete.GATES:
		var want: int = int(_course[_gate])
		var due := _gate_time(_gate) - _t
		var cx := s.x * 0.5
		var col := GOLD if absf(due) < (0.8 if _easy else 0.5) else CREAM
		_stage.draw_line(Vector2(cx - 60, 60), Vector2(cx + 60, 60), CREAM, 2.0)
		_stage.draw_string(ThemeDB.fallback_font, Vector2(cx - 60 + 120.0 * clampf(due / 1.5, 0.0, 1.0) - 6, 50), "<" if want < 0 else ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, col)
		_stage.draw_string(ThemeDB.fallback_font, Vector2(cx - 6, 90), "now", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
	else:
		_stage.draw_string(ThemeDB.fallback_font, Vector2(s.x * 0.5 - 90, 60), "HOLD CONFIRM: DIVE" if _t < _gate_time(Fete.GATES) + 1.7 else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, GOLD)

func _draw_bog(s: Vector2) -> void:
	_stage.draw_rect(Rect2(0, s.y * 0.45, s.x, s.y * 0.55), PEAT)
	_stage.draw_rect(Rect2(40, s.y * 0.6, s.x - 80, 50), Color("2c3a2a"))
	# the snorkeller moves along the trench, there on length one and back on length two
	var done := clampf(float(_next_beat) / float(maxi(_pattern.size(), 1)), 0.0, 1.0)
	var lens := done * Fete.BOG_LENGTHS
	var frac := lens - floorf(minf(lens, float(Fete.BOG_LENGTHS) - 0.001))
	var x := 60.0 + frac * (s.x - 120.0) if int(lens) % 2 == 0 else s.x - 60.0 - frac * (s.x - 120.0)
	_stage.draw_circle(Vector2(x, s.y * 0.6 + 20), 13.0, BAD if _flash > 0.0 else CREAM)
	_stage.draw_line(Vector2(x, s.y * 0.6 + 8), Vector2(x, s.y * 0.6 - 14), GOLD, 3.0)
	# the beat ring closes on the cue for the next beat; B marks a breath
	if _next_beat < _pattern.size():
		var itv := float(_bbeat.interval)
		var due := 1.0 + float(_next_beat) * itv - _t
		var c := Vector2(s.x * 0.5, 80)
		var r := 14.0 + 50.0 * clampf(due / itv, 0.0, 1.5)
		_stage.draw_arc(c, r, 0.0, TAU, 32, GOLD, 3.0)
		_stage.draw_arc(c, 14.0, 0.0, TAU, 32, CREAM, 2.0)
		_stage.draw_string(ThemeDB.fallback_font, c + Vector2(-8, 8), "B" if _pattern[_next_beat] == "b" else "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, CREAM)

func _draw_welly(s: Vector2) -> void:
	var ground := s.y * 0.8
	_stage.draw_rect(Rect2(0, ground, s.x, s.y - ground), GRASS)
	for m in range(10, 61, 10):
		var mx := 80.0 + float(m) / 60.0 * (s.x - 160.0)
		_stage.draw_line(Vector2(mx, ground), Vector2(mx, ground + 12), CREAM, 2.0)
	var tx := 80.0 + Fete.WELLY_TARGET / 60.0 * (s.x - 160.0)
	_stage.draw_line(Vector2(tx, ground - 70), Vector2(tx, ground), GOLD, 3.0)
	# the wind flag
	_stage.draw_line(Vector2(s.x - 70, ground), Vector2(s.x - 70, ground - 80), CREAM, 3.0)
	_stage.draw_line(Vector2(s.x - 70, ground - 78), Vector2(s.x - 70 + _wind * 14.0, ground - 70), GOLD, 5.0)
	# power bar and angle dial
	var bar := Rect2(60, 40, 300, 28)
	_stage.draw_rect(bar, Color(0, 0, 0, 0.35))
	_stage.draw_rect(Rect2(bar.position.x, bar.position.y + 5, bar.size.x * _power, bar.size.y - 10), GOOD)
	var o := Vector2(120, ground - 20)
	var a := deg_to_rad(_angle)
	_stage.draw_line(o, o + Vector2(cos(a), -sin(a)) * 80.0, GOLD, 4.0)
	if _easy:
		for deg in [35.0, 55.0]:
			_stage.draw_line(o, o + Vector2(cos(deg_to_rad(deg)), -sin(deg_to_rad(deg))) * 60.0, GOOD, 1.5)
	# the boot in flight, then where it landed
	if _phase == 2:
		var f := clampf(1.0 - _pause / 1.6, 0.0, 1.0)
		var dist_px := _last / 60.0 * (s.x - 160.0)
		var p := Vector2(80.0 + dist_px * f, ground - sin(f * PI) * 120.0)
		_stage.draw_rect(Rect2(p.x - 6, p.y - 10, 12, 20), Color("3d6b3d"))
