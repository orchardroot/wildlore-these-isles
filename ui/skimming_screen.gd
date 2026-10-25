extends MenuBase
## Stone skimming (story command {"do": "skim"}): pick a stone (Run cycles them), set the angle it meets the water at
## (left and right) and how hard you throw (up and down), then Confirm. Three throws, and your best count of skips is
## your score against the local's. About 20 degrees is the sweet spot; Easier skimming steadies the stone and shades
## that band on the angle gauge. The numbers live in Skimming. Closes with {"won": bool, "draw": bool, "best": int}
## (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a throw part way through).

const STAGE := Vector2(900, 300)
const TURN := 14.0            # degrees per second
const POWER_RATE := 0.45      # fraction per second
const WATER_Y := 190.0
const METRES := 70.0          # the stage shows at least this much water

var _venue_id := "easdale"
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _angle := 20.0
var _power := 0.8
var _stone_i := 0
var _throws := 0
var _best := 0
var _last := -1
var _their_best := -1
var _anim: Dictionary = {}     # {hops: Array, t: float, scale: float, skips: int}
var _busy := false
var _over := false
var _wait := 0.4
var _msg := "Pick your stone, set the angle and the power."
var _easy := false
var _stage: Control
var _info: Label

func _build() -> void:
	set_title("Stone skimming")
	_easy = Settings.easy_darts
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	content.add_child(root)
	_stage = Control.new()
	_stage.custom_minimum_size = STAGE
	_stage.draw.connect(_draw_stage)
	root.add_child(_stage)
	_info = UIKit.label("", 26, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["confirm", "Throw"], ["run", "Change stone"], ["cancel", "Walk away"]])
	_rival = Skimming.venue(_venue_id).rival
	_refresh()

func setup(arg: String) -> void:
	_venue_id = arg if not Skimming.venue(arg).is_empty() else "easdale"
	_rival = Skimming.venue(_venue_id).rival
	if arg.begins_with("dev"):   # a good throw landing in the shallows, two stones used
		_rival = Skimming.venue("easdale").rival
		_throws = 2
		_best = 6
		_last = 6
		_angle = 19.0
		var st := Skimming.stone("slate_thin")
		var res := Skimming.skim(st, 19.0, 0.9, Rng.new(4))
		_anim = {"hops": res.hops, "t": 99.0, "scale": maxf(1.0, float(res.distance) * 1.05) / (STAGE.x - 120.0), "skips": int(res.skips)}
		_msg = "That is a proper skim. Best so far: 6."
	_refresh()

func _stone() -> Dictionary:
	return Skimming.stones()[_stone_i]

func _process(delta: float) -> void:
	if _over:
		return
	_wait = maxf(0.0, _wait - delta)
	if _busy:
		_anim.t = float(_anim.t) + delta
		_stage.queue_redraw()
		if float(_anim.t) >= _anim_length():
			_landed()
		return
	if _wait > 0.0:
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v != Vector2.ZERO:
		_angle = clampf(_angle + v.x * TURN * delta, float(Skimming.ANGLE_MIN), float(Skimming.ANGLE_MAX))
		_power = clampf(_power - v.y * POWER_RATE * delta, 0.2, 1.0)
		_refresh()
	if Input.is_action_just_pressed("run"):
		_stone_i = (_stone_i + 1) % Skimming.stones().size()
		Audio.sfx("cursor")
		_refresh()
	if Input.is_action_just_pressed("confirm"):
		_throw()

func _on_cancel() -> void:
	if _over or _busy:
		return
	close(null)

func _throw() -> void:
	var res := Skimming.skim(_stone(), _angle, _power, _rng, Skimming.wobble_scale(_easy))
	var span := maxf(float(res.distance) * 1.05, METRES)
	_anim = {"hops": res.hops, "t": 0.0, "scale": span / (STAGE.x - 120.0), "skips": int(res.skips), "res": res}
	_busy = true
	Audio.sfx("confirm")
	_msg = ""
	_refresh()

## Seconds the stone takes: a short flight to the first splash, then each hop a little quicker than the last.
func _anim_length() -> float:
	return _hop_start(int(_anim.hops.size())) + 0.45

func _hop_start(i: int) -> float:
	var t := 0.4
	for k in i:
		t += maxf(0.16, 0.3 - 0.012 * float(k))
	return t

func _landed() -> void:
	_busy = false
	var res: Dictionary = _anim.res
	_last = int(res.skips)
	_best = maxi(_best, _last)
	_throws += 1
	_msg = "%d skip%s. %s" % [_last, "" if _last == 1 else "s", Skimming.advice(res, _angle)]
	if _throws >= Skimming.THROWS:
		_their_best = Skimming.local_best(_rival, _rng)
		_over = true
		var who := str(_rival.get("who", "The local")).split(",")[0]
		_msg += "\n\nYour best: %d. %s skims %d." % [_best, who, _their_best]
		_refresh()
		await get_tree().create_timer(2.2).timeout
		close({"won": _best > _their_best, "draw": _best == _their_best, "best": _best})
		return
	_wait = 0.5
	_refresh()

func _refresh() -> void:
	if _info == null:
		return
	var st := _stone()
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var lines := "Throw %d of %d.  Best: %d.   Against %s.\n%s (%s)\nAngle %d degrees.  Power %d%%." % [mini(_throws + 1, Skimming.THROWS), Skimming.THROWS, _best, who, str(st.name), str(st.desc), roundi(_angle), roundi(_power * 100.0)]
	if _msg != "":
		lines += "\n" + _msg
	_info.text = lines
	_stage.queue_redraw()

# ---- drawing

func _draw_stage() -> void:
	var w := STAGE.x
	_stage.draw_rect(Rect2(0, 0, w, WATER_Y), Color("8fb4c8"))
	_stage.draw_rect(Rect2(0, 60, w, WATER_Y - 60), Color("a9c7d4"))
	_stage.draw_rect(Rect2(0, WATER_Y, w, STAGE.y - WATER_Y), Color("2f5d73"))
	_stage.draw_rect(Rect2(0, WATER_Y, w, 3), Color("d8ecf2"))
	_stage.draw_rect(Rect2(0, WATER_Y - 14, 90, 14 + STAGE.y - WATER_Y), Color("6b5c48"))   # the shingle you stand on
	_stage.draw_circle(Vector2(62, WATER_Y - 38), 12.0, Color("e8c8a0"))
	_stage.draw_rect(Rect2(52, WATER_Y - 26, 20, 26), Color("3a5a7a"))
	_draw_gauge()
	if _anim.is_empty():
		return
	var hops: Array = _anim.hops
	var sc: float = _anim.scale
	var t: float = _anim.t
	var x0 := 100.0
	var y0 := WATER_Y - 30.0
	var land := x0
	var prev := Vector2(x0, y0)
	var shown := 0
	for i in hops.size() + 1:
		var start := _hop_start(i)
		var dur := maxf(0.16, 0.3 - 0.012 * float(i)) if i < hops.size() else 0.45
		var to_x := land + float(hops[i]) / sc if i < hops.size() else land + 6.0
		var to := Vector2(to_x, WATER_Y)
		if i == 0:
			start = 0.0
			dur = 0.4
		else:
			start = _hop_start(i) - dur
		if t < start:
			break
		var f := clampf((t - start) / dur, 0.0, 1.0)
		var height := clampf((to.x - prev.x) * 0.3, 4.0, 70.0) if i > 0 else 40.0
		var pts := PackedVector2Array()
		for k in 11:
			var u := float(k) / 10.0 * f
			var p := prev.lerp(to, u)
			p.y = lerpf(prev.y, to.y, u) - sin(u * PI) * height * (1.0 if i > 0 else 0.0)
			pts.append(p)
		_stage.draw_polyline(pts, Color(1, 1, 1, 0.55), 2.0)
		if f >= 1.0:
			if i < hops.size():
				_stage.draw_arc(to + Vector2(0, 2), 7.0, 0.0, TAU, 14, Color("d8ecf2"), 2.0)
				shown += 1
			else:
				_stage.draw_arc(to + Vector2(0, 2), 10.0, 0.0, TAU, 14, Color("d8ecf2"), 2.0)
		else:
			_stage.draw_circle(pts[pts.size() - 1], 5.0, Color("4a4a50"))
		prev = to
		land = to_x
		if i == 0:
			prev = Vector2(to_x, WATER_Y)
	_stage.draw_string(ThemeDB.fallback_font, Vector2(w - 190, 40), "Skips: %d" % shown if t < _anim_length() else "Skips: %d" % int(_anim.skips), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIKit.CREAM)

func _draw_gauge() -> void:
	# the angle gauge: a stone tilted over the water line; Easier skimming shades 15 to 25 degrees
	var c := Vector2(150, WATER_Y + 52)
	var r := 70.0
	_stage.draw_line(c, c + Vector2(r, 0), Color("d8ecf2"), 2.0)
	if _easy:
		_stage.draw_arc(c, r * 0.8, -deg_to_rad(25.0), -deg_to_rad(15.0), 8, Color("e8c872"), 8.0)
	var a := deg_to_rad(_angle)
	_stage.draw_line(c - Vector2(cos(a), -sin(a)) * 12.0, c + Vector2(cos(a), -sin(a)) * r * 0.9, Color("c8c0b0"), 6.0)
	_stage.draw_string(ThemeDB.fallback_font, c + Vector2(r + 12, 6), "%d°" % roundi(_angle), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.CREAM)
