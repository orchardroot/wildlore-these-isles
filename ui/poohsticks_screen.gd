extends MenuBase
## Poohsticks (story command {"do": "poohsticks"}): a footbridge over a river seen from above. Up and down pick the
## lane to drop your stick into, Run changes the stick, Confirm drops. Watch the leaves and ripples to read the
## current: the middle runs fast, the banks are slow, reeds and eddies hold sticks up. First stick out from under
## the bridge wins the race; five races, most wins takes the match. Easier Poohsticks marks the quick water.
## The numbers live in Poohsticks. Closes with {"won": bool, "draw": bool, "wins": int, "losses": int} (null if you walk out).
## setup arg: "<venue id>" or "<venue id>:<stake>" (the stake is paid by the story command). Dev: "dev".

const STAGE := Vector2(1184, 330)
const LANE_H := 34.0
const WATER_TOP := 46.0
const BRIDGE_X := 400.0
const BRIDGE_W := 64.0                       # pixels for SPAN metres
const SHOW := 3.0                            # the animation runs this much faster than the river
const LEAF := [Color("c8863a"), Color("a6b84a"), Color("d9a53a"), Color("8aa04a")]

var _venue_id := "oxford"
var _v: Dictionary = {}
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _easy := false
var _river: Dictionary = {}
var _lane := 3
var _stick_i := 1
var _race := 0                               # races finished
var _wins := 0
var _losses := 0
var _anim: Dictionary = {}                   # {me, them: {run, lane}, t, done}
var _wait := 0.5
var _over := false
var _msg := "Read the water, pick a lane and drop."
var _clock := 0.0
var _stage: Control
var _info: Label
var _flash := 0.0

func _build() -> void:
	set_title("Poohsticks")
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
	_info = UIKit.label("", 24, UIKit.CREAM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_info)
	set_hints([["move_up", "Lane"], ["run", "Change stick"], ["confirm", "Drop"], ["cancel", "Walk away"]])
	_load_venue("oxford")
	_new_river()
	_refresh()

func _load_venue(id: String) -> void:
	_venue_id = id if not Poohsticks.venue(id).is_empty() else "oxford"
	_v = Poohsticks.venue(_venue_id)
	_rival = _v.get("rival", {})

func setup(arg: String) -> void:
	var id := arg.split(":")[0]
	_load_venue("oxford" if id.begins_with("dev") else id)
	_new_river()
	if id.begins_with("dev"):
		_race = 2
		_wins = 1
		_losses = 1
		_lane = Poohsticks.best_lane(_river)
		var me := Poohsticks.run(_river, _lane, Poohsticks.stick(1), Rng.new(3))
		var tl := Poohsticks.local_lane(_river, 0.7, Rng.new(4))
		_anim = {"me": {"run": me, "lane": _lane, "col": Color("efe3c0")}, "them": {"run": Poohsticks.run(_river, tl, Poohsticks.stick(1), Rng.new(5)), "lane": tl, "col": Color("d9772c")}, "t": 2.4, "done": false, "dev": true}
		_msg = ""
	_refresh()

func _new_river() -> void:
	_river = Poohsticks.river(_v, _rng)

# ---- play

func _process(delta: float) -> void:
	_clock += delta
	_flash = maxf(0.0, _flash - delta)
	if _over:
		_stage.queue_redraw()
		return
	if not _anim.is_empty():
		if not bool(_anim.get("dev", false)):
			_anim.t = float(_anim.t) + delta
		_check_finish()
		_stage.queue_redraw()
		return
	_wait = maxf(0.0, _wait - delta)
	if _wait <= 0.0:
		if Input.is_action_just_pressed("move_up"):
			_lane = (_lane + Poohsticks.LANES - 1) % Poohsticks.LANES
			Audio.sfx("cursor")
			_refresh()
		elif Input.is_action_just_pressed("move_down"):
			_lane = (_lane + 1) % Poohsticks.LANES
			Audio.sfx("cursor")
			_refresh()
		if Input.is_action_just_pressed("run"):
			_stick_i = (_stick_i + 1) % Poohsticks.sticks().size()
			Audio.sfx("cursor")
			_refresh()
		if Input.is_action_just_pressed("confirm"):
			_drop()
	_stage.queue_redraw()

func _on_cancel() -> void:
	if _over or not _anim.is_empty():
		return
	close(null)

func _drop() -> void:
	var tl := Poohsticks.local_lane(_river, float(_rival.get("skill", 0.7)), _rng)
	var me := Poohsticks.run(_river, _lane, Poohsticks.stick(_stick_i), _rng)
	var them := Poohsticks.run(_river, tl, Poohsticks.stick(1), _rng)
	_anim = {"me": {"run": me, "lane": _lane, "col": Color("efe3c0")}, "them": {"run": them, "lane": tl, "col": Color("d9772c")}, "t": 0.0, "done": false}
	Audio.sfx("snare_throw")
	_msg = ""
	_refresh()

## Seconds (animation clock) at which a stick has fully come out from under the deck.
func _emerge_t(w: Dictionary) -> float:
	return float(w.run.time) / SHOW

func _check_finish() -> void:
	if bool(_anim.get("done", false)) or bool(_anim.get("dev", false)):
		return
	var te: float = _anim.t
	if not _anim.has("sound_me") and te >= 0.35:
		_anim["sound_me"] = true
		Audio.sfx_at("splash", -6.0, 1.1)
	if te >= minf(_emerge_t(_anim.me), _emerge_t(_anim.them)) and not _anim.has("first"):
		_anim["first"] = "me" if _emerge_t(_anim.me) <= _emerge_t(_anim.them) else "them"
		Audio.sfx("hit_weak")
		_flash = 0.5
	if te >= maxf(_emerge_t(_anim.me), _emerge_t(_anim.them)) + 0.8:
		_anim.done = true
		_finish_race()

func _finish_race() -> void:
	var a: float = _anim.me.run.time
	var b: float = _anim.them.run.time
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var snag_note := ""
	if bool(_anim.me.run.snagged):
		snag_note = " Your stick got tangled in the reeds."
	elif bool(_anim.them.run.snagged):
		snag_note = " %s's stick got caught in the reeds." % who
	var gap := absf(a - b)
	_race += 1
	if a < b:
		_wins += 1
		_msg = "Yours, by %.1f seconds.%s" % [gap, snag_note]
		Audio.sfx("stat_up")
	else:
		_losses += 1
		_msg = "%s's, by %.1f seconds.%s" % [who, gap, snag_note]
		Audio.sfx("stat_down")
	_anim = {}
	_new_river()
	_wait = 0.9
	if _race >= Poohsticks.RACES:
		_end_match()
		return
	_refresh()

func _end_match() -> void:
	_over = true
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var won := _wins > _losses
	var draw := _wins == _losses
	_msg += "\n\n%s" % ("You take the match, %d to %d." % [_wins, _losses] if won else ("All square, %d each. Nobody is happy." % _wins if draw else "%s takes it, %d to %d." % [who, _losses, _wins]))
	Audio.sfx("level_up" if won else "cancel")
	_refresh()
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree():
		return
	await PiecePrompt.after_game(self, "poohsticks", float(_wins))
	close({"won": won, "draw": draw, "wins": _wins, "losses": _losses})

func _refresh() -> void:
	if _info == null:
		return
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var st := Poohsticks.stick(_stick_i)
	var lines := "Race %d of %d.   You %d, %s %d.\n%s: %s" % [mini(_race + 1, Poohsticks.RACES), Poohsticks.RACES, _wins, who, _losses, str(st.name), str(st.desc)]
	if _msg != "":
		lines += "\n" + _msg
	_info.text = lines
	_stage.queue_redraw()

# ---- drawing

func _lane_y(i: int) -> float:
	return WATER_TOP + (float(i) + 0.5) * LANE_H

func _draw_stage() -> void:
	var w := STAGE.x
	var wb := WATER_TOP + LANE_H * Poohsticks.LANES
	# banks, then water
	_stage.draw_rect(Rect2(0, 0, w, STAGE.y), Color("5f8f45"))
	for k in 12:
		_stage.draw_rect(Rect2(0, k * 28.0, w, 14.0), Color(1, 1, 1, 0.035))
	for i in Poohsticks.LANES:
		var depth := 1.0 - absf(float(i) - 3.0) / 4.5
		var col := Color("5d9aa6").lerp(Color("2f6f86"), depth * 0.8)
		_stage.draw_rect(Rect2(0, WATER_TOP + float(i) * LANE_H, w, LANE_H + 1.0), col)
	_stage.draw_rect(Rect2(0, WATER_TOP - 5, w, 6), Color("3a4a28"))
	_stage.draw_rect(Rect2(0, wb - 1, w, 6), Color("3a4a28"))
	_draw_banks(wb)
	if _river.is_empty():
		return
	_draw_current(wb)
	_draw_sticks_before_deck()
	_draw_bridge(wb)
	_draw_sticks_after_deck()
	_draw_lane_marker()
	_draw_hud()
	if _flash > 0.0:
		_stage.draw_rect(Rect2(BRIDGE_X + BRIDGE_W - 4, WATER_TOP, 10, wb - WATER_TOP), Color(1, 1, 1, _flash * 0.6))

func _draw_banks(wb: float) -> void:
	# willows and reeds along both banks
	for k in 11:
		var x := 30.0 + float(k) * 94.0 + float((k * 37) % 23)
		var top := k % 2 == 0
		var cy := 18.0 if top else wb + 28.0
		var r := 22.0 + float((k * 13) % 9)
		_stage.draw_circle(Vector2(x + 6, cy + 5), r, Color(0, 0, 0, 0.18))
		_stage.draw_circle(Vector2(x, cy), r, Color("2f5a2a"))
		_stage.draw_circle(Vector2(x - 5, cy - 5), r * 0.7, Color("3f7a3c"))
		_stage.draw_circle(Vector2(x - 8, cy - 8), r * 0.35, Color("5f9a4a"))
	for k in 40:
		var x := 8.0 + float(k) * 25.0
		var y := WATER_TOP - 2.0 if k % 2 == 0 else wb + 1.0
		var sway := sin(_clock * 1.6 + float(k)) * 2.0
		for j in 3:
			_stage.draw_line(Vector2(x + float(j) * 3.0, y), Vector2(x + float(j) * 3.0 + sway, y + (-13.0 if k % 2 == 0 else 13.0)), Color("6f8a3a"), 2.0)

func _draw_current(wb: float) -> void:
	var sp: Array = _river.speed
	for i in Poohsticks.LANES:
		var y0 := _lane_y(i)
		var v := float(sp[i])
		var dir := 1.0 if i != int(_river.eddy) else -1.0
		var rate := v * 10.0 * SHOW * 0.6 * dir   # px/s of the ripples
		var n := 9
		for k in n:
			var base := float(k) * (STAGE.x / float(n)) + float((i * 53 + k * 17) % 41)
			var x := fposmod(base + _clock * rate, STAGE.x + 60.0) - 30.0
			var len_px := 10.0 + absf(v) * 40.0
			var yy := y0 + sin(float(k) * 2.1 + float(i)) * 8.0
			_stage.draw_line(Vector2(x, yy), Vector2(x + len_px * (1.0 if dir > 0.0 else -1.0), yy), Color(1, 1, 1, 0.22 + 0.15 * minf(1.0, v)), 2.0)
		# one leaf per lane tells you the speed straight
		var lx := fposmod(60.0 * float(i) + _clock * rate * 1.1, STAGE.x + 40.0) - 20.0
		_stage.draw_circle(Vector2(lx, y0 + 8.0), 4.0, LEAF[i % LEAF.size()])
		_stage.draw_circle(Vector2(lx + 2, y0 + 7.0), 2.0, LEAF[i % LEAF.size()].lightened(0.3))
	var eddy: int = _river.eddy
	if eddy >= 0:
		var c := Vector2(BRIDGE_X - 70.0, _lane_y(eddy))
		for k in 3:
			_stage.draw_arc(c, 8.0 + float(k) * 6.0, _clock * 2.0 + float(k), _clock * 2.0 + float(k) + 4.4, 12, Color(1, 1, 1, 0.3), 2.0)
	var sn: int = _river.snag
	if sn >= 0:
		var c2 := Vector2(BRIDGE_X - 22.0, _lane_y(sn))
		for k in 7:
			var sway := sin(_clock * 2.0 + float(k)) * 2.0
			_stage.draw_line(c2 + Vector2(float(k) * 3.0 - 9.0, 12.0), c2 + Vector2(float(k) * 3.0 - 9.0 + sway, -12.0 + float(k % 3) * 3.0), Color("7a9a3a"), 2.5)
		_stage.draw_circle(c2 + Vector2(0, 14), 5.0, Color("6b5c48"))

func _draw_bridge(wb: float) -> void:
	var x0 := BRIDGE_X
	var top := WATER_TOP - 22.0
	var h := wb - WATER_TOP + 44.0
	_stage.draw_rect(Rect2(x0 + 8, top + 8, BRIDGE_W, h), Color(0, 0, 0, 0.22))   # its shadow on the water
	_stage.draw_rect(Rect2(x0, top, BRIDGE_W, h), Color("8a6a46"))
	var k := 0.0
	while k < h:
		_stage.draw_rect(Rect2(x0, top + k, BRIDGE_W, 1.5), Color("5c4630"))
		k += 11.0
	for rail_x in [x0, x0 + BRIDGE_W - 5.0]:
		_stage.draw_rect(Rect2(rail_x, top, 5.0, h), Color("5c4630"))
		var p := 0.0
		while p < h:
			_stage.draw_rect(Rect2(rail_x - 1, top + p, 7.0, 7.0), Color("3d2e1f"))
			p += 36.0
	_stage.draw_rect(Rect2(x0 + 2, top, 2.0, h), Color(1, 1, 1, 0.18))

func _stick_pos(w: Dictionary, te: float) -> Vector2:
	var run: Dictionary = w.run
	var t_real := te * SHOW
	var stall := float(run.stall)
	var v := float(run.speed) * 10.0   # px per real second
	var hold_at := Poohsticks.SPAN * 0.4 / float(run.speed)
	var dist := 0.0
	if t_real <= hold_at:
		dist = t_real * v
	elif t_real <= hold_at + stall:
		dist = hold_at * v
	else:
		dist = (t_real - stall) * v
	var wob := sin(te * 5.0 + float(w.lane)) * 2.0
	return Vector2(BRIDGE_X + dist, _lane_y(int(w.lane)) + wob)

func _draw_one_stick(w: Dictionary, te: float, rival: bool) -> void:
	var p := _stick_pos(w, te)
	if p.x < BRIDGE_X + 1.0:
		p.x = BRIDGE_X + 1.0
	var ang := 0.12 * sin(te * 3.0 + float(w.lane))
	var dir := Vector2(cos(ang), sin(ang)) * 17.0
	_stage.draw_line(p - dir + Vector2(2, 3), p + dir + Vector2(2, 3), Color(0, 0, 0, 0.25), 5.0)
	_stage.draw_line(p - dir, p + dir, w.col.darkened(0.35), 5.0)
	_stage.draw_line(p - dir, p + dir, w.col, 3.0)
	if bool(w.run.snagged) and te * SHOW > Poohsticks.SPAN * 0.4 / float(w.run.speed) and te * SHOW < Poohsticks.SPAN * 0.4 / float(w.run.speed) + float(w.run.stall):
		_stage.draw_string(ThemeDB.fallback_font, p + Vector2(-6, -16), "stuck", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2e8cf"))

func _draw_sticks_before_deck() -> void:
	if _anim.is_empty():
		return
	for k in ["me", "them"]:
		var p := _stick_pos(_anim[k], float(_anim.t))
		if p.x < BRIDGE_X + BRIDGE_W:
			_draw_one_stick(_anim[k], float(_anim.t), k == "them")

func _draw_sticks_after_deck() -> void:
	if _anim.is_empty():
		return
	for k in ["me", "them"]:
		var p := _stick_pos(_anim[k], float(_anim.t))
		if p.x >= BRIDGE_X + BRIDGE_W:
			_draw_one_stick(_anim[k], float(_anim.t), k == "them")
			if not bool(_anim.get("done", false)):
				var first: String = str(_anim.get("first", ""))
				if first == k:
					_stage.draw_string(ThemeDB.fallback_font, p + Vector2(-8, -20), "YOU" if k == "me" else str(_rival.get("who", "Them")).split(" ")[0].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8c872"))

func _draw_lane_marker() -> void:
	if not _anim.is_empty() or _over:
		return
	var y := _lane_y(_lane)
	_stage.draw_rect(Rect2(0, y - LANE_H * 0.5, BRIDGE_X, LANE_H), Color(1, 1, 1, 0.1))
	# your stick, held over the rail
	var bob := sin(_clock * 3.0) * 2.0
	var col: Color = Color("efe3c0")
	_stage.draw_line(Vector2(BRIDGE_X - 14, y - 4 + bob), Vector2(BRIDGE_X + 18, y - 4 + bob), Color(0, 0, 0, 0.3), 6.0)
	_stage.draw_line(Vector2(BRIDGE_X - 16, y - 8 + bob), Vector2(BRIDGE_X + 16, y - 8 + bob), col, 4.0)
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(BRIDGE_X - 44, y - 8), Vector2(BRIDGE_X - 30, y - 15), Vector2(BRIDGE_X - 30, y - 1)]), Color("e8c872"))
	if _easy:
		var b := Poohsticks.best_lane(_river)
		_stage.draw_string(ThemeDB.fallback_font, Vector2(BRIDGE_X - 180, _lane_y(b) + 6), "quick water >", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8c872"))

func _draw_hud() -> void:
	var who := str(_rival.get("who", "The local")).split(",")[0]
	_stage.draw_rect(Rect2(10, 10, 230, 30), Color(0.1, 0.12, 0.16, 0.7))
	_stage.draw_string(ThemeDB.fallback_font, Vector2(18, 31), "Race %d/%d   %d : %d" % [mini(_race + 1, Poohsticks.RACES), Poohsticks.RACES, _wins, _losses], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.CREAM)
	if not _anim.is_empty() and float(_anim.t) > 0.2 and not bool(_anim.get("dev", false)):
		var a: float = _anim.me.run.time
		var b: float = _anim.them.run.time
		if bool(_anim.get("done", false)) or _anim.has("first"):
			_stage.draw_rect(Rect2(STAGE.x - 280, 10, 270, 56), Color(0.1, 0.12, 0.16, 0.8))
			_stage.draw_string(ThemeDB.fallback_font, Vector2(STAGE.x - 270, 33), "You  %.1f s" % a, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("efe3c0"))
			_stage.draw_string(ThemeDB.fallback_font, Vector2(STAGE.x - 270, 57), "%s  %.1f s" % [who, b], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("d9772c"))
	if bool(_anim.get("dev", false)):
		pass
