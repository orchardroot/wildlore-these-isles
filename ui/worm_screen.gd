extends MenuBase
## Worm charming (story command {"do": "worms"}): a three-by-three plot and a fork. Direction keys move the fork, Confirm
## thrums the earth and wants to land on the beat (the ring closes on it, and the click is the beat), Run shoos a bird off
## before it lands. Steady taps build the rhythm and bring the worms up; a sloppy beat scares them down and calls the
## birds. A patch gives up its worms and goes pale: move on. Easier minigames widen the timing windows. The rules live in
## WormCharming. Closes with {"won": bool, "draw": bool, "worms": int} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a plot mid-charm with a bird on its way).

const STAGE := Vector2(1000, 450)
const CELL := 112.0
const PLOT_ORIGIN := Vector2(330, 62)
const COUNT_IN := 4

var _venue_id := "willaston"
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _st: Dictionary = {}
var _easy := false
var _clock := -4.0 * 0.625            # negative during the count-in; beats fall on multiples of the period
var _last_beat := -1
var _over := false
var _frozen := false                  # dev screenshots hold the scene still
var _msg := "Tap Confirm on every beat. Steady does it."
var _verdict := ""
var _verdict_age := 9.0
var _floaters: Array = []
var _pulse := 0.0
var _stage: Control
var _info: Label
var _fork_shake := 0.0

func _build() -> void:
	set_title("Worm charming")
	_easy = Settings.easy_darts
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = STAGE
	_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["move", "Move the fork"], ["confirm", "Thrum on the beat"], ["run", "Shoo the bird"], ["cancel", "Walk away"]])
	_begin(_venue_id)

func setup(arg: String) -> void:
	var id := arg.split(":")[0]
	_venue_id = id if not WormCharming.venue(id).is_empty() else "willaston"
	if _stage != null:
		_begin(_venue_id)
	if arg.begins_with("dev"):
		_begin("willaston")
		_clock = 21.3
		_st.t = 21.3
		_st.meter = 0.8
		_st.cursor = 4
		_st.bucket = 17
		_st.stolen = 2
		_st.cells = [0.9, 0.3, 0.8, 0.45, 0.2, 0.5, 0.95, 0.6, 0.85]
		_st.last_tap = 21.2
		for k in 7:
			_st.worms.append({"cell": [1, 3, 4, 4, 5, 7, 4][k], "age": 0.2 + 0.2 * float(k % 4), "off": Vector2(float(k % 3) * 0.3 - 0.3, float(k % 2) * 0.3 - 0.15)})
		_st.bird = {"cell": 6, "eta": 0.7}
		_frozen = true
		_verdict = "perfect"
		_verdict_age = 0.1
		_msg = "Perfect. The ground is humming."
		_refresh()

func _begin(id: String) -> void:
	_rival = WormCharming.venue(id).rival
	_st = WormCharming.start(_rng, _easy)
	_clock = -float(COUNT_IN) * WormCharming.period()
	_last_beat = -1
	_over = false
	_refresh()

func _process(delta: float) -> void:
	if _st.is_empty():
		return
	if _frozen:
		_stage.queue_redraw()
		return
	_pulse += delta
	_verdict_age += delta
	_fork_shake = maxf(0.0, _fork_shake - delta * 5.0)
	for f in _floaters:
		f.age = float(f.age) + delta
	_floaters = _floaters.filter(func(f): return float(f.age) < 1.2)
	if _over or _frozen:
		_stage.queue_redraw()
		return
	_clock += delta
	var p := WormCharming.period()
	var beat := floori(_clock / p)
	if beat != _last_beat:
		_last_beat = beat
		if _clock > -p * 1.5 or beat >= 0:
			Audio.sfx("cursor")   # the metronome
		_pulse = 0.0
	if _clock >= 0.0:
		if Input.is_action_just_pressed("move_left"):
			WormCharming.move_cursor(_st, -1, 0)
		elif Input.is_action_just_pressed("move_right"):
			WormCharming.move_cursor(_st, 1, 0)
		elif Input.is_action_just_pressed("move_up"):
			WormCharming.move_cursor(_st, 0, -1)
		elif Input.is_action_just_pressed("move_down"):
			WormCharming.move_cursor(_st, 0, 1)
		if Input.is_action_just_pressed("run"):
			if WormCharming.shoo(_st):
				Audio.sfx("bump")
				_pop("Shoo!", Vector2(PLOT_ORIGIN.x + 1.5 * CELL, 40), Color("ffffff"))
				_msg = "Shooed. Back to the beat."
			else:
				Audio.sfx("cancel")
		if Input.is_action_just_pressed("confirm"):
			_tap()
		var ev := WormCharming.step(_st, delta)
		for e in ev:
			match str(e):
				"bagged":
					if int(_st.bucket) % 5 == 0:
						Audio.sfx("item")
				"bird":
					Audio.sfx("crow")
					_msg = "A bird! Press Shoo."
				"stolen":
					Audio.sfx("bump")
					_msg = "The bird got some. Shoo it sooner."
					_pop("Stolen!", Vector2(PLOT_ORIGIN.x + float(int(_st.cursor) % 3) * CELL, PLOT_ORIGIN.y + 30), Color("e98b73"))
	_refresh()
	if bool(_st.done):
		_finish()

func _tap() -> void:
	# the screen's clock and the sim's clock agree: both start at zero when the count-in ends
	var v := WormCharming.tap(_st, _clock)
	_verdict = v
	_verdict_age = 0.0
	_fork_shake = 1.0
	match v:
		"perfect":
			Audio.sfx("confirm")
			_msg = "On the beat."
		"good":
			Audio.sfx("step_soft")
			_msg = "Close. Tighter to the click."
		_:
			Audio.sfx("deny")
			_msg = "Off the beat: the worms dive. Wait for the click."

func _pop(text: String, at: Vector2, col: Color) -> void:
	_floaters.append({"text": text, "pos": at, "age": 0.0, "colour": col})

func _on_cancel() -> void:
	if _over:
		return
	close(null)

func _finish() -> void:
	_over = true
	var mine := int(_st.bucket)
	var theirs := WormCharming.local_score(_rival, _rng)
	var who := str(_rival.get("who", "The local")).split(",")[0]
	Audio.sfx("badge" if mine > theirs else "cancel")
	_msg = "%d worms counted, %d lost to birds, all put back.  %s\n%s counted %d." % [mine, int(_st.stolen), WormCharming.advice(_st), who, theirs]
	_refresh()
	await get_tree().create_timer(2.8).timeout
	await PiecePrompt.after_game(self, WormCharming.PIECE_ID, float(mine))
	close({"won": mine > theirs, "draw": mine == theirs, "worms": mine})

func _refresh() -> void:
	if _info == null or _st.is_empty():
		return
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var left := maxf(0.0, WormCharming.duration() - float(_st.t))
	_info.text = "Worms %d.   Against %s.   %s\n%s" % [int(_st.bucket), who, ("Count in..." if _clock < 0.0 else "%d s left." % ceili(left)), _msg]
	_stage.queue_redraw()

# ---- drawing

func _cell_rect(i: int) -> Rect2:
	return Rect2(PLOT_ORIGIN + Vector2(float(i % 3), float(i / 3)) * CELL, Vector2(CELL, CELL))

func _draw_stage() -> void:
	if _st.is_empty():
		return
	var d := _stage
	# a village green behind the plot: sky, hills, a white marquee, bunting, grass
	d.draw_rect(Rect2(Vector2.ZERO, STAGE), Color("a9cce0"))
	d.draw_circle(Vector2(120, 80), 52.0, Color("ffffff", 0.55))
	d.draw_circle(Vector2(170, 90), 40.0, Color("ffffff", 0.55))
	d.draw_circle(Vector2(850, 60), 44.0, Color("ffffff", 0.5))
	d.draw_colored_polygon(PackedVector2Array([Vector2(0, 190), Vector2(160, 110), Vector2(330, 175), Vector2(520, 100), Vector2(760, 170), Vector2(1000, 120), Vector2(1000, 260), Vector2(0, 260)]), Color("6f9a74"))
	d.draw_rect(Rect2(0, 230, STAGE.x, STAGE.y - 230), Color("66994a"))
	d.draw_rect(Rect2(0, 230, STAGE.x, 6), Color("4d7a38"))
	_draw_marquee(d, Vector2(80, 150))
	_draw_marquee(d, Vector2(820, 160))
	for i in 24:   # bunting across the top
		var bx := float(i) * 42.0
		d.draw_line(Vector2(bx, 20 + sin(float(i)) * 3.0), Vector2(bx + 42, 20 + sin(float(i + 1)) * 3.0), Color("574636"), 1.5)
		d.draw_colored_polygon(PackedVector2Array([Vector2(bx + 8, 21), Vector2(bx + 28, 21), Vector2(bx + 18, 40)]), [Color("c0392b"), Color("e8c872"), Color("3f7cac"), Color("f2f0e8")][i % 4])
	# the plot: three metres square, string-edged
	var plot := Rect2(PLOT_ORIGIN - Vector2(8, 8), Vector2(CELL * 3 + 16, CELL * 3 + 16))
	d.draw_rect(plot, Color("4a3a2a"))
	for i in 9:
		var r := _cell_rect(i)
		var rich: float = _st.cells[i]
		var soil := Color("3d2b1c").lerp(Color("9b8466"), 1.0 - rich)
		d.draw_rect(r.grow(-3), soil)
		for k in 7:
			var sp := r.position + Vector2(10 + float((k * 41 + i * 13) % 90), 12 + float((k * 29 + i * 7) % 88))
			d.draw_circle(sp, 2.5, soil.darkened(0.2))
	d.draw_rect(plot, Color("e8dcc0"), false, 3.0)
	for c in [plot.position, plot.position + Vector2(plot.size.x, 0), plot.position + Vector2(0, plot.size.y), plot.end]:
		d.draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Color("c0392b"))   # corner pegs
	# the thrum: rings out from the fork on a good tap
	var cur: Rect2 = _cell_rect(_st.cursor)
	if _verdict_age < 0.5 and _verdict != "miss":
		var u := _verdict_age / 0.5
		for ring in 3:
			d.draw_arc(cur.get_center(), (30.0 + float(ring) * 26.0) * (0.4 + u), 0.0, TAU, 32, Color("f6e7a0", (1.0 - u) * 0.6), 3.0)
	# worms
	for w in _st.worms:
		_draw_worm(d, w)
	# the bird's shadow and the bird
	if not (_st.bird as Dictionary).is_empty():
		var b: Dictionary = _st.bird
		var br := _cell_rect(int(b.cell))
		var u := clampf(1.0 - float(b.eta) / WormCharming.WARN, 0.0, 1.0)
		d.draw_set_transform(br.get_center() + Vector2(0, 22), 0.0, Vector2(1.0, 0.45))
		d.draw_circle(Vector2.ZERO, 10.0 + 34.0 * u, Color(0, 0, 0, 0.18 + 0.2 * u))
		d.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var by := br.get_center().y - 150.0 * (1.0 - u)
		var bp := Vector2(br.get_center().x, by)
		d.draw_circle(bp, 14.0, Color("2b2b33"))
		d.draw_circle(bp + Vector2(10, -6), 8.0, Color("2b2b33"))
		d.draw_colored_polygon(PackedVector2Array([bp + Vector2(16, -7), bp + Vector2(26, -4), bp + Vector2(16, -2)]), Color("e8a23a"))
		d.draw_colored_polygon(PackedVector2Array([bp + Vector2(-4, -2), bp + Vector2(-26, -14 - 8.0 * sin(_pulse * 30.0)), bp + Vector2(-10, 8)]), Color("3a3a45"))
		d.draw_string(ThemeDB.fallback_font, bp + Vector2(-26, -26), "Shoo!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffd34d"))
	# the fork
	var fc := cur.get_center() + Vector2(float(randf_range(-1.0, 1.0)) * _fork_shake * 3.0, 0)
	d.draw_rect(cur.grow(-1), Color("f6e7a0"), false, 4.0)
	d.draw_line(fc + Vector2(0, -90 + _fork_shake * 6.0), fc + Vector2(0, 0), Color("6b4a2a"), 6.0)
	for k in [-8, 0, 8]:
		d.draw_line(fc + Vector2(k, 0), fc + Vector2(k, 16), Color("b8b8c0"), 3.0)
	d.draw_line(fc + Vector2(-8, 0), fc + Vector2(8, 0), Color("b8b8c0"), 3.0)
	_draw_beat(d)
	_draw_hud(d)
	for f in _floaters:
		var a := 1.0 - float(f.age) / 1.2
		var fp: Vector2 = f.pos + Vector2(0, -float(f.age) * 40.0)
		d.draw_string(ThemeDB.fallback_font, fp, str(f.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(f.colour, a))

func _draw_marquee(d: Control, at: Vector2) -> void:
	d.draw_rect(Rect2(at, Vector2(110, 60)), Color("f2f0e8"))
	d.draw_colored_polygon(PackedVector2Array([at + Vector2(-10, 0), at + Vector2(55, -42), at + Vector2(120, 0)]), Color("e8dcc0"))
	for k in 6:
		d.draw_rect(Rect2(at + Vector2(float(k) * 18.0, 0), Vector2(9, 60)), Color("c0392b", 0.55))
	d.draw_rect(Rect2(at + Vector2(42, 28), Vector2(26, 32)), Color("574636"))

func _draw_worm(d: Control, w: Dictionary) -> void:
	var r := _cell_rect(int(w.cell))
	var base := r.get_center() + Vector2(w.off.x * 70.0, w.off.y * 70.0)
	var u := clampf(float(w.age) / 0.3, 0.0, 1.0)
	var fade := clampf((WormCharming.LIFE - float(w.age)) / 0.3, 0.0, 1.0)
	var pts := PackedVector2Array()
	for k in 9:
		var f := float(k) / 8.0
		pts.append(base + Vector2(sin(f * 5.0 + float(w.age) * 9.0) * 5.0, -f * 30.0 * u))
	d.draw_polyline(pts, Color("d98b8b", fade), 6.0)
	d.draw_circle(pts[pts.size() - 1], 4.0, Color("c97878", fade))

func _draw_beat(d: Control) -> void:
	# a metronome strip: a ring that closes on the beat, and a pip that flashes on it
	var c := Vector2(150, 360)
	var p := WormCharming.period()
	var u := clampf(fmod(maxf(_clock, 0.0), p) / p, 0.0, 1.0)
	var near := 1.0 - clampf(absf(WormCharming.offset(_clock)) / (WormCharming.windows(_easy).x + 0.02), 0.0, 1.0)
	d.draw_circle(c, 34.0, Color(0.05, 0.07, 0.1, 0.55))
	d.draw_arc(c, 34.0, 0.0, TAU, 40, Color("f2e8cf", 0.5), 2.0)
	d.draw_arc(c, 34.0 + (1.0 - u) * 38.0, 0.0, TAU, 40, Color("f6e7a0", 0.25 + 0.5 * u), 3.0)
	d.draw_circle(c, 10.0 + 12.0 * near, Color("f6e7a0", 0.3 + 0.6 * near))
	d.draw_string(ThemeDB.fallback_font, c + Vector2(-60, 70), "BEAT", HORIZONTAL_ALIGNMENT_CENTER, 120, 18, UIKit.MUTED)
	if _verdict_age < 0.9 and _clock > 0.0:
		var col := Color("f6e7a0") if _verdict == "perfect" else (Color("cde7b0") if _verdict == "good" else Color("e98b73"))
		d.draw_string(ThemeDB.fallback_font, c + Vector2(-60, -48), _verdict.capitalize() + "!" if _verdict != "miss" else "Off!", HORIZONTAL_ALIGNMENT_CENTER, 120, 26, Color(col, 1.0 - _verdict_age / 0.9))
	if _clock < 0.0:
		var n := ceili(-_clock / p)
		d.draw_string(ThemeDB.fallback_font, Vector2(PLOT_ORIGIN.x, 52), "Get ready... %d" % n, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UIKit.CREAM)

func _draw_hud(d: Control) -> void:
	d.draw_rect(Rect2(20, 268, 260, 6), Color(0, 0, 0, 0.4))
	d.draw_rect(Rect2(20, 268, 260.0 * float(_st.meter), 6), Color("f6e7a0") if float(_st.meter) < 0.9 else Color("9fd36a"))
	d.draw_string(ThemeDB.fallback_font, Vector2(20, 262), "Rhythm", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.CREAM)
	d.draw_rect(Rect2(700, 300, 280, 100), Color(0.05, 0.07, 0.1, 0.55))
	d.draw_string(ThemeDB.fallback_font, Vector2(716, 340), "In the bucket: %d" % int(_st.bucket), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UIKit.CREAM)
	d.draw_string(ThemeDB.fallback_font, Vector2(716, 376), "Lost to birds: %d" % int(_st.stolen), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.MUTED)
	var left := maxf(0.0, WormCharming.duration() - float(_st.t))
	d.draw_rect(Rect2(PLOT_ORIGIN.x - 8, PLOT_ORIGIN.y + CELL * 3 + 18, CELL * 3 + 16, 8), Color(0, 0, 0, 0.4))
	d.draw_rect(Rect2(PLOT_ORIGIN.x - 8, PLOT_ORIGIN.y + CELL * 3 + 18, (CELL * 3 + 16) * left / WormCharming.duration(), 8), Color("e8c872"))
