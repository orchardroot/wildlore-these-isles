extends MenuBase
## Sheepdog trials (story command {"do": "sheepdog"}): your lead creature works the flock. Direction keys walk the
## dog, Run dashes (it spooks them), Confirm lies the dog down (it settles them). Get round behind the sheep and walk
## them through the gate or gates into the pen before the clock runs out. Easier minigames widen the gates, add time and
## make the sheep calmer. The rules and the flock live in SheepdogTrials. Closes with {"won": bool, "draw": bool,
## "penned": int} (null if you walk out).
## setup arg: "<venue id>" (dev: "dev" shows a run part way through).

const S := 10.0                           # pixels per field unit
const PAD := Vector2(20, 22)              # where the field starts inside the stage (the hedge and wall are around it)
const STAGE := Vector2(1000, 450)
const GRASS := Color("5f8f46")
const GRASS_B := Color("68984e")
const WOOD := Color("7a5a38")
const WOOD_DARK := Color("4e3a24")

var _venue_id := "longshaw"
var _v: Dictionary = {}
var _rival: Dictionary = {}
var _rng := Rng.new(int(Time.get_ticks_usec()))
var _st: Dictionary = {}
var _easy := false
var _lie := false
var _started := false
var _over := false
var _wait := 0.5
var _msg := "Walk round behind the flock, then walk them at the gate."
var _tufts: Array = []
var _floaters: Array = []                 # [{text, pos, age, colour}]
var _bark_cd := 0.0
var _step_cd := 0.0
var _stage: Control
var _info: Label
var _dog_sprite: AnimSprite

func _build() -> void:
	set_title("SheepdogTrials trials")
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
	var tr := Rng.new(77)
	for i in 90:
		_tufts.append([Vector2(tr.roll() * SheepdogTrials.FIELD.x, tr.roll() * SheepdogTrials.FIELD.y), 0.5 + tr.roll() * 0.8, tr.roll()])
	_dog_sprite = AnimSprite.new()
	_dog_sprite.visible = false
	_dog_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_dog_sprite)
	var lead: Creature = Game.data.party[0] if not Game.data.party.is_empty() else null
	if lead != null:
		_dog_sprite.show_species(lead.species.id, "icon", 2, false, lead.variant, lead.form, lead.sex)
		_dog_sprite.visible = true
	set_hints([["move", "Walk the dog"], ["run", "Dash"], ["confirm", "Lie down"], ["cancel", "Walk away"]])
	_begin(_venue_id)

func setup(arg: String) -> void:
	var id := arg.split(":")[0]
	_venue_id = id if not SheepdogTrials.venue(id).is_empty() else "longshaw"
	if _stage != null:
		_begin(_venue_id)
	if arg.begins_with("dev"):   # four penned, three in the open, a gate passed, 62 seconds gone
		_venue_id = "lakes"
		_begin("lakes")
		var i := 0
		for s in _st.sheep:
			if i < 4:
				s.penned = true
				s.through = 2
				s.p = Vector2(6.0 + float(i % 2) * 5.0, 15.0 + float(i / 2) * 6.0)
			elif i == 4:
				s.p = Vector2(30.0, 17.0)
				s.through = 2
			else:
				s.p = Vector2(66.0 + float(i) * 2.5, 12.0 + float(i) * 3.0)
			i += 1
		_st.penned = 4
		_st.through = 5
		_st.t = 62.0
		_st.dog = Vector2(76.0, 22.0)
		_started = true
		_wait = 0.0
		_msg = "Four in. Steady, now. Walk the rest at the gate."
		_floaters.append({"text": "Penned!", "pos": Vector2(9, 12), "age": 0.3, "colour": Color("f6e7a0")})
		_refresh()

func _begin(id: String) -> void:
	_v = SheepdogTrials.venue(id)
	_rival = _v.rival
	_st = SheepdogTrials.start(_v, _easy, _rng)
	_started = false
	_over = false
	_lie = false
	_wait = 0.5
	_floaters.clear()
	_refresh()

func _process(delta: float) -> void:
	if _st.is_empty():
		return
	for f in _floaters:
		f.age = float(f.age) + delta
	_floaters = _floaters.filter(func(f): return float(f.age) < 1.4)
	_bark_cd = maxf(0.0, _bark_cd - delta)
	_step_cd = maxf(0.0, _step_cd - delta)
	if _over:
		_place_dog()
		_stage.queue_redraw()
		return
	_wait = maxf(0.0, _wait - delta)
	if _wait > 0.0:
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dash := Input.is_action_pressed("run")
	if Input.is_action_just_pressed("confirm"):
		_lie = not _lie
		Audio.sfx("cursor")
		_msg = "Lie down. The flock settles." if _lie else "Up you get."
		_started = true
	if v != Vector2.ZERO:
		_started = true
		if _lie:
			_lie = false
	if _started:
		var ev := SheepdogTrials.step(_st, delta, v, dash, _lie)
		_react(ev)
		if v != Vector2.ZERO and dash and _step_cd <= 0.0:
			Audio.sfx("step_grass")
			_step_cd = 0.3
	_refresh()
	if bool(_st.done):
		_finish()

func _react(ev: Array) -> void:
	for e in ev:
		match str(e):
			"gate":
				Audio.sfx("confirm")
				_pop("Through!", _gate_point(), Color("f6e7a0"))
			"pen":
				Audio.sfx("item")
				_pop("Penned!", Vector2(10.0, 20.0), Color("f6e7a0"))
				_msg = "%d in the pen." % int(_st.penned)
			"scatter":
				if _bark_cd <= 0.0:
					Audio.sfx("bump")
					_bark_cd = 1.6
					_pop("Baa!", _flock_centre(), Color("ffffff"))
					_msg = "Too fast: they are scattering. Ease off, or lie down."

func _gate_point() -> Vector2:
	var g: Array = _st.gates
	return Vector2(float(g[0].x), float(g[0].y)) if not g.is_empty() else Vector2(40, 20)

func _flock_centre() -> Vector2:
	var c := Vector2.ZERO
	var n := 0
	for s in _st.sheep:
		if not s.penned:
			c += s.p
			n += 1
	return c / float(maxi(1, n))

func _pop(text: String, at: Vector2, col: Color) -> void:
	_floaters.append({"text": text, "pos": at, "age": 0.0, "colour": col})

func _on_cancel() -> void:
	if _over:
		return
	close(null)

func _finish() -> void:
	_over = true
	Audio.sfx("badge" if int(_st.penned) >= _st.sheep.size() else "cancel")
	var mine := SheepdogTrials.score(_st)
	var theirs := SheepdogTrials.local_score(_rival, _rng)
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var left := int(maxf(0.0, float(_st.limit) - float(_st.t)))
	_msg = "%d of %d penned%s.  %s\n%s penned %d." % [int(_st.penned), _st.sheep.size(), (", %d seconds to spare" % left) if int(_st.penned) >= _st.sheep.size() else "", SheepdogTrials.advice(_st), who, int(theirs)]
	_refresh()
	await get_tree().create_timer(2.6).timeout
	await PiecePrompt.after_game(self, SheepdogTrials.PIECE_ID, float(_st.penned))
	close({"won": mine > theirs, "draw": absf(mine - theirs) < 0.0001, "penned": int(_st.penned)})

func _refresh() -> void:
	if _info == null or _st.is_empty():
		return
	var who := str(_rival.get("who", "The local")).split(",")[0]
	var lead: Creature = Game.data.party[0] if not Game.data.party.is_empty() else null
	var head := "%s working the flock.   Against %s." % [lead.display_name() if lead != null else "Your dog", who]
	_info.text = head + "\n" + _msg
	_place_dog()
	_stage.queue_redraw()

func _place_dog() -> void:
	if _dog_sprite == null or _st.is_empty():
		return
	_dog_sprite.position = _px(_st.dog) - Vector2(32, 44)
	_dog_sprite.modulate = Color(0.85, 0.9, 1.0) if _lie else Color.WHITE

# ---- drawing

func _px(p: Vector2) -> Vector2:
	return PAD + p * S

func _draw_stage() -> void:
	if _st.is_empty():
		return
	var d := _stage
	var fw := SheepdogTrials.FIELD.x * S
	var fh := SheepdogTrials.FIELD.y * S
	# beyond the wall: hills and hedge, a marquee and onlookers along the top
	d.draw_rect(Rect2(Vector2.ZERO, STAGE), Color("2d4a2b"))
	d.draw_rect(Rect2(0, 0, STAGE.x, PAD.y + 4), Color("3d5f3a"))
	for i in 12:
		var hx := float(i) * 90.0 + 10.0
		d.draw_circle(Vector2(hx, 6), 34.0 + float((i * 37) % 22), Color("456b42"))
	d.draw_rect(Rect2(PAD.x - 10, PAD.y - 10, fw + 20, fh + 20), Color("8c8880"))   # the dry-stone wall
	for i in 80:
		var sx := PAD.x - 10 + float(i) * (fw + 20) / 80.0
		d.draw_rect(Rect2(sx, PAD.y - 10, 9, 4), Color("a8a49a" if i % 3 else "77736b"))
		d.draw_rect(Rect2(sx, PAD.y + fh + 6, 9, 4), Color("a8a49a" if i % 3 else "77736b"))
	d.draw_rect(Rect2(PAD, Vector2(fw, fh)), GRASS)
	for i in 8:   # mown stripes
		d.draw_rect(Rect2(PAD.x + float(i) * fw / 8.0, PAD.y, fw / 16.0, fh), GRASS_B)
	for t in _tufts:
		var tp := _px(t[0])
		d.draw_line(tp, tp + Vector2(-2, -6) * float(t[1]), Color("4a7a38"), 1.5)
		d.draw_line(tp, tp + Vector2(2, -7) * float(t[1]), Color("4a7a38"), 1.5)
	_draw_pen(d)
	_draw_gates(d)
	# a ring showing how close the dog can get before they move
	var flight := SheepdogTrials.FLIGHT * (0.45 if _lie else (1.4 if _st.running else 1.0)) * (0.82 if _easy else 1.0)
	var dp := _px(_st.dog)
	d.draw_circle(dp, flight * S, Color(1, 1, 1, 0.06 if not _st.running else 0.12))
	d.draw_arc(dp, flight * S, 0.0, TAU, 48, Color(1, 1, 1, 0.28), 2.0)
	d.draw_set_transform(dp + Vector2(0, 8), 0.0, Vector2(1.0, 0.4))
	d.draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3))
	d.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not _dog_sprite.visible:
		d.draw_circle(dp, 12.0, Color("3a3a40"))
	for s in _st.sheep:
		_draw_sheep(d, s)
	for f in _floaters:
		var a := 1.0 - float(f.age) / 1.4
		var fp := _px(f.pos) + Vector2(-30, -30 - float(f.age) * 40.0)
		d.draw_string(ThemeDB.fallback_font, fp + Vector2(1, 1), str(f.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0, 0, 0, a * 0.6))
		d.draw_string(ThemeDB.fallback_font, fp, str(f.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(f.colour, a))
	_draw_hud(d)

func _draw_pen(d: Control) -> void:
	var r := SheepdogTrials.PEN
	d.draw_rect(Rect2(_px(r.position), r.size * S), Color("c9b074"))
	for i in 18:
		var sp := _px(r.position + Vector2(1.0 + float((i * 7) % 14), 1.0 + float((i * 5) % 17)))
		d.draw_line(sp, sp + Vector2(5, -2), Color("e3cd8a"), 2.0)
	d.draw_string(ThemeDB.fallback_font, _px(Vector2(r.position.x + 3.5, r.end.y - 1.4)), "THE PEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("6b5530"))
	# the open side, with two white posts and a little hurdle swung back
	var top := _px(Vector2(r.end.x, r.position.y))
	var bot := _px(Vector2(r.end.x, r.end.y))
	d.draw_line(top, top + Vector2(10, -16), WOOD, 5.0)
	d.draw_line(bot, bot + Vector2(10, 16), WOOD, 5.0)
	d.draw_circle(top, 6.0, Color("f2f0e8"))
	d.draw_circle(bot, 6.0, Color("f2f0e8"))
	for w in SheepdogTrials.walls({"gates": []}):
		_draw_fence(d, w)

func _draw_gates(d: Control) -> void:
	for w in _st.walls:
		if not SheepdogTrials.PEN.grow(1.0).encloses(w):
			_draw_fence(d, w)
	var i := 1
	for g in _st.gates:
		var gw: float = float(g.w) + (3.0 if _easy else 0.0)
		var top := _px(Vector2(g.x, float(g.y) - gw * 0.5))
		var bot := _px(Vector2(g.x, float(g.y) + gw * 0.5))
		for p in [top, bot]:
			d.draw_circle(p, 7.0, Color("f2f0e8"))
			d.draw_circle(p, 7.0, WOOD_DARK, false, 2.0)
		d.draw_line(top, top + Vector2(0, -22), Color("c0392b"), 3.0)   # a little flag on each post
		d.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -22), top + Vector2(14, -17), top + Vector2(0, -12)]), Color("c0392b"))
		d.draw_dashed_line(top + Vector2(0, 12), bot - Vector2(0, 12), Color(1, 1, 1, 0.5), 2.0, 8.0)
		d.draw_string(ThemeDB.fallback_font, top + Vector2(-34, -28), "GATE %d" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f6e7a0"))
		i += 1

func _draw_fence(d: Control, w: Rect2) -> void:
	var a := _px(w.position)
	var sz := w.size * S
	d.draw_rect(Rect2(a, sz), WOOD)
	d.draw_rect(Rect2(a, sz), WOOD_DARK, false, 1.5)
	var n := int(maxf(sz.x, sz.y) / 28.0)
	for k in n + 1:
		var f := float(k) / float(maxi(1, n))
		var pp := a + Vector2(sz.x * f if sz.x > sz.y else sz.x * 0.5, sz.y * f if sz.y >= sz.x else sz.y * 0.5)
		d.draw_circle(pp, 4.0, WOOD_DARK)

func _draw_sheep(d: Control, s: Dictionary) -> void:
	var p := _px(s.p)
	var heading: Vector2 = (s.v as Vector2).normalized() if (s.v as Vector2).length() > 0.3 else Vector2(-1, 0)
	var wool := Color("f1efe8") if not s.penned else Color("e4e0d4")
	d.draw_set_transform(p + Vector2(0, 7), 0.0, Vector2(1.0, 0.4))
	d.draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.25))
	d.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for leg in [Vector2(-6, 8), Vector2(6, 8)]:
		d.draw_line(p + leg, p + leg + Vector2(0, 5), Color("3a3430"), 2.5)
	d.draw_circle(p + Vector2(-5, 0), 9.0, wool)
	d.draw_circle(p + Vector2(5, 1), 9.0, wool)
	d.draw_circle(p + Vector2(0, -4), 9.0, wool)
	d.draw_circle(p + Vector2(0, 3), 8.0, wool)
	var head := p + heading * 11.0 + Vector2(0, -1)
	d.draw_circle(head, 5.0, Color("2f2a28"))
	d.draw_circle(head + Vector2(-3, -4), 2.2, Color("2f2a28"))
	d.draw_circle(head + Vector2(3, -4), 2.2, Color("2f2a28"))
	if float(s.scare) > 0.55 and not s.penned:
		d.draw_string(ThemeDB.fallback_font, p + Vector2(-3, -20), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffd34d"))

func _draw_hud(d: Control) -> void:
	var left := maxf(0.0, float(_st.limit) - float(_st.t))
	var frac := left / float(_st.limit)
	var bar := Rect2(PAD.x + 230, PAD.y + 8, 520, 14)
	d.draw_rect(Rect2(PAD.x + 8, PAD.y + 6, 750, 46), Color(0.05, 0.07, 0.1, 0.62))
	d.draw_rect(bar, Color(0, 0, 0, 0.5))
	var col := Color("e8c872") if frac > 0.25 else Color("d9593f")
	d.draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), col)
	d.draw_string(ThemeDB.fallback_font, Vector2(PAD.x + 18, PAD.y + 38), "Penned %d / %d" % [int(_st.penned), _st.sheep.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UIKit.CREAM)
	d.draw_string(ThemeDB.fallback_font, Vector2(bar.end.x + 10, PAD.y + 22), "%d s" % ceili(left), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.CREAM)
	d.draw_string(ThemeDB.fallback_font, Vector2(PAD.x + 230, PAD.y + 44), "Dog: %s" % ("lying down" if _lie else ("dashing" if _st.running else "walking")), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.MUTED)
