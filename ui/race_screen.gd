extends CasinoBase
## The races (see Racing): the day's card from Aintree, at the course or on the screens in the Glasgow and Belfast
## bookies, and the Aintree novice race with one of your own team. Pick a runner, win or each-way, and they're
## off: the stakes come out of your purse and the result is rolled and saved before a single creature moves. Then
## a short side-on race with commentary, and the payout.
## setup arg: "aintree" | "glasgow" | "belfast" | "novice" (plus ":dev" for screenshots, ":dev:race" mid-race).

const VENUES := {
	"aintree": "Aintree, the County Stand", "glasgow": "Glasgow bookies, live from Aintree",
	"belfast": "Belfast bookies, live from Aintree", "novice": "Aintree, the Novice Stakes",
}
const RACE_SECS := 11.0
const PX_PER_POINT := 14.0

var venue := "aintree"
var _card: Dictionary = {}
var _phase := "card"           # pick | card | race | result
var _sel := 0
var _slip: Array = []          # {runner, stake, each_way}
var _each_way := false
var _root: Control
var _rows: Array = []
var _detail: VBoxContainer
var _slip_l: Label
var _ew_btn: Button
var _go_btn: Button
var _run: Dictionary = {}
var _t := 0.0
var _view: Control
var _comment: Label
var _lines: Array = []
var _sprites := {}             # species -> [frame0, frame1]
var _staked := 0
var _skip := false

func _build() -> void:
	set_title("The Races")
	with_chips = false
	stakes = [5, 10, 20, 50, 100, 250, 500]
	stake_i = 1
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(_root)

func setup(arg: String) -> void:
	var parts := arg.split(":")
	venue = parts[0] if VENUES.has(parts[0]) else "aintree"
	_dev = parts.size() > 1 and parts[1] == "dev"
	set_title(VENUES[venue])
	if venue == "novice":
		_show_pick()
	else:
		_load_card()
		_show_card()
	if parts.size() > 2 and parts[2] == "race":  # dev: a race already running, for screenshots
		_slip = [{"runner": 0, "stake": 10, "each_way": false}]
		_run = Racing.run(_card, Rng.new(5))
		_lines = Racing.commentary(_card, _run)
		_show_race()
		_t = RACE_SECS * 0.62
		_comment.text = str(_lines[2])

func _going() -> Dictionary:
	return Racing.going_for(str(Game.data.weather))

func _load_card() -> void:
	_card = Racing.card(Calendar.today_key(), Racing.next_race(Game.data), _going(), Game.dex)
	_sel = 0
	_slip = []

# ---------------------------------------------------------------- picking your runner (novice)

func _show_pick() -> void:
	_phase = "pick"
	UIKit.clear(_root)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	_root.add_child(v)
	var intro := UIKit.label("The Aintree Novice Stakes, a mile and a half on the Flat for creatures who've never raced. Free to enter, once a day. Prize money for the first three. Who's running?", 24)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(intro)
	var btns := []
	for c in Game.data.party:
		var cr: Creature = c
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var b := make_button("", _enter.bind(cr), 520)
		b.custom_minimum_size = Vector2(520, 64)
		var icon := AnimSprite.new()
		icon.show_species(str(cr.species.id), "icon", 2, false, cr.variant, cr.form, cr.sex)
		icon.position = Vector2(8, 0)
		b.add_child(icon)
		b.text = "            %s   Lv %d     Pace %d   Stamina %d" % [cr.display_name(), cr.level, cr.calc_stat("spd"), cr.max_hp()]
		btns.append(b)
		v.add_child(b)
		if cr.is_fainted():
			b.disabled = true
			b.text += "   (needs the Sanctuary)"
	UIKit.wrap_focus(btns)
	if not btns.is_empty():
		UIKit.focus_later(btns[0])
	set_hints([["updown", "Choose"], ["confirm", "Enter"], ["cancel", "Not today"]])

func _enter(c: Creature) -> void:
	_card = Racing.novice_card(Calendar.today_key(), c, Game.dex, _going())
	_sel = Racing.yours(_card)
	_slip = []
	_show_card()

# ---------------------------------------------------------------- the card

func _show_card() -> void:
	_phase = "card"
	UIKit.clear(_root)
	_rows = []
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 18)
	_root.add_child(h)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	h.add_child(left)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	left.add_child(head)
	head.add_child(serif(26, UIKit.GOLD, "%s  %s" % [_card.time, _card.name]))
	head.add_child(UIKit.fill())
	head.add_child(UIKit.label("%s   Going: %s" % [_card.distance, _card.going.name], 20, UIKit.MUTED))
	var n: int = _card.runners.size()
	var terms := UIKit.label("Each-way: %d places at 1/%d the odds.   Form: latest run on the right (F fell, P pulled up)." % [Racing.places_for(n), Racing.place_fraction(n)[1]], 18, UIKit.MUTED)
	left.add_child(terms)
	for i in n:
		var row := _runner_row(i)
		left.add_child(row)
		_rows.append(row)
	UIKit.wrap_focus(_rows)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(330, 0)
	side.add_theme_constant_override("separation", 8)
	h.add_child(side)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 4)
	side.add_child(_detail)
	side.add_child(stake_picker())
	_ew_btn = make_button("", _toggle_ew, 330)
	side.add_child(_ew_btn)
	_go_btn = make_button("", _off, 330)
	side.add_child(_go_btn)
	if not _card.get("novice", false):
		side.add_child(make_button("Skip to the next race", _skip_race, 330))
	_slip_l = UIKit.label("", 20, UIKit.CREAM)
	_slip_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_slip_l)
	_refresh_card()
	UIKit.focus_later(_rows[_sel])
	set_hints([["updown", "Runner"], ["confirm", "Back it"], ["leftright", "Stake"], ["cancel", "Leave"]])

func _runner_row(i: int) -> Button:
	var r: Dictionary = _card.runners[i]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 52)
	UIKit.compact(b, 2)
	b.focus_entered.connect(_pick.bind(i))
	b.pressed.connect(_back.bind(i))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var num := serif(22, UIKit.MUTED, str(i + 1))
	num.custom_minimum_size = Vector2(26, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(num)
	var silk := Control.new()
	silk.custom_minimum_size = Vector2(34, 40)
	silk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	silk.draw.connect(func(): _draw_silks(silk, Rect2(2, 6, 30, 32), r.silks))
	row.add_child(silk)
	var icon := AnimSprite.new()
	icon.show_species(str(r.species), "icon", 1)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -6)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nm := UIKit.label(str(r.name) + ("   (yours)" if r.get("yours", false) else ""), 24, UIKit.GOLD if r.get("yours", false) else UIKit.CREAM)
	names.add_child(nm)
	names.add_child(UIKit.label(str(Game.dex.get_species(str(r.species)).get("name", r.species)), 17, UIKit.MUTED))
	row.add_child(names)
	var form := UIKit.label(str(r.form), 22, Color("d8cfb4"))
	form.custom_minimum_size = Vector2(70, 0)
	row.add_child(form)
	var odds := serif(28, UIKit.GOLD, Odds.text(r.odds))
	odds.custom_minimum_size = Vector2(110, 0)
	odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(odds)
	return b

func _pick(i: int) -> void:
	_sel = i
	Audio.sfx("cursor")
	_refresh_card()

func _refresh_card() -> void:
	if _detail == null:
		return
	UIKit.clear(_detail)
	var r: Dictionary = _card.runners[_sel]
	_detail.add_child(serif(26, UIKit.CREAM, str(r.name)))
	var sp := Game.dex.get_species(str(r.species))
	_detail.add_child(UIKit.label("%s, %s" % [sp.get("name", r.species), "/".join(sp.get("types", []))], 18, UIKit.MUTED))
	_detail.add_child(_bar("Pace", float(r.pace) / 130.0))
	_detail.add_child(_bar("Stamina", float(r.stamina) / 130.0))
	var pref := Racing.going_pref(sp)
	var g := "Loves the mud." if pref > 0 else ("Wants it fast." if pref < 0 else "Goes on any ground.")
	_detail.add_child(UIKit.label("%s  Form %s." % [g, r.form], 18, Color("d8cfb4")))
	_detail.add_child(hand(26, UIKit.GOLD, "%s   (%d%% on the book)" % [Odds.text(r.odds), roundi(Odds.implied(r.odds) * 100)]))
	_ew_btn.text = "Bet type:  %s" % ("Each-way (stake x2)" if _each_way else "Win")
	_go_btn.text = ("Go to post" if _card.get("novice", false) else "They're off!") + ("" if _slip.is_empty() else "  (%s staked)" % Purse.text(_slip_total()))
	_go_btn.disabled = _slip.is_empty() and not _card.get("novice", false)
	var lines := []
	for e in _slip:
		lines.append("%s %s on %s at %s" % [Purse.text(int(e.stake)), "each-way" if e.each_way else "to win", _card.runners[int(e.runner)].name, Odds.text(_card.runners[int(e.runner)].odds)])
	_slip_l.text = ("Your slip:\n" + "\n".join(lines)) if not lines.is_empty() else "Pick a runner and press %s to back it. Up to three bets a race." % UIKit.key_for("confirm")

func _bar(label: String, frac: float) -> Control:
	var h := HBoxContainer.new()
	var l := UIKit.label(label, 18, UIKit.MUTED)
	l.custom_minimum_size = Vector2(80, 0)
	h.add_child(l)
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.value = clampf(frac, 0.05, 1.0)
	b.custom_minimum_size = Vector2(200, 12)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_stylebox_override("background", UIKit.box(Color("0d0f15"), Color("5a5f6e"), 1, 3, 0))
	b.add_theme_stylebox_override("fill", UIKit.box(UIKit.GOLD, Color(0, 0, 0, 0), 0, 3, 0))
	h.add_child(b)
	return h

func _toggle_ew() -> void:
	_each_way = not _each_way
	_refresh_card()

func _slip_total() -> int:
	var t := 0
	for e in _slip:
		t += int(e.stake) * (2 if e.each_way else 1)
	return t

func _back(i: int) -> void:
	if _slip.size() >= 3:
		banner("Three bets a race. The clerk's pencil is only so long.", LOSE, 26)
		return
	var cost := _slip_total() + stake() * (2 if _each_way else 1)
	var why := why_not(cost)
	if why != "":
		Audio.sfx("bump")
		banner(why, LOSE, 26)
		return
	_slip.append({"runner": i, "stake": stake(), "each_way": _each_way})
	Audio.sfx("shop_bell")
	_refresh_card()
	UIKit.focus_later(_go_btn)

func _skip_race() -> void:
	Racing.race_done(Game.data)  # the race is run without you; you'll never see how it went
	commit()
	_load_card()
	_show_card()

## The off: stakes taken, the result rolled from the save's stream, saved. Only then does anything move.
func _off() -> void:
	var novice := bool(_card.get("novice", false))
	if _slip.is_empty() and not novice:
		return
	_staked = _slip_total()
	if _staked > 0:
		if why_not(_staked) != "":
			banner(why_not(_staked), LOSE, 26)
			return
		Punt.stake(Game.data, _staked, false)
	_run = Racing.run(_card, Punt.rng(Game.data, "race"))
	if novice:
		Racing.mark_novice(Game.data)
	else:
		Racing.race_done(Game.data)
	commit()
	_lines = Racing.commentary(_card, _run)
	_show_race()

# ---------------------------------------------------------------- the race

func _show_race() -> void:
	_phase = "race"
	UIKit.clear(_root)
	_t = 0.0
	_skip = false
	for r in _card.runners:
		if not _sprites.has(r.species):
			var sheet := AnimSprite.load_sheet(str(r.species), "front")
			var frames := []
			for k in 2:
				var a := AtlasTexture.new()
				a.atlas = sheet
				var fp := float(sheet.get_height())  # square frames, as wide as the sheet is tall
				a.region = Rect2(k * fp if sheet.get_width() >= fp * 2.0 else 0.0, 0, fp, fp)
				frames.append(a)
			_sprites[r.species] = frames
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	_root.add_child(v)
	var frame := felt_panel(Color("0d0f15"), BRASS, 0)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(frame)
	_view = Control.new()
	_view.clip_contents = true
	_view.draw.connect(_draw_race)
	frame.add_child(_view)
	_comment = hand(34, UIKit.CREAM)
	_comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment.custom_minimum_size = Vector2(0, 90)
	v.add_child(_comment)
	set_hints([["confirm", "Skip to the finish"]])
	_comment.text = str(_lines[0]) if not _lines.is_empty() else ""
	set_process(true)

func _process(delta: float) -> void:
	if _phase != "race":
		return
	var before := _t
	_t += delta * (6.0 if _skip else 1.0)
	var total := RACE_SECS * 1.15
	for k in _lines.size():
		var at := RACE_SECS * (0.03 + 0.24 * k) if k < _lines.size() - 1 else RACE_SECS * 1.0
		if before < at and _t >= at:
			_comment.text = str(_lines[k])
			_comment.modulate.a = 0.0
			create_tween().tween_property(_comment, "modulate:a", 1.0, 0.25)
			if k == _lines.size() - 1:
				Audio.sfx("badge")
	if int(before * 3.0) != int(_t * 3.0):
		Audio.sfx_at("atk_thud", -14.0, 0.8 + fmod(_t, 0.3))
	_view.queue_redraw()
	if _t >= total:
		_finish_race()

func _input(event: InputEvent) -> void:
	if _phase == "race":
		if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
			_skip = true
			get_viewport().set_input_as_handled()
		return
	super._input(event)

## A runner's distance behind the leader (in rating points) at race time `u` (0..1), between checkpoints.
func _gap(i: int, u: float) -> float:
	var legs: Array = _run.legs
	var times := [0.12, 0.35, 0.6, 0.85, 1.0]
	var g := []
	for c in legs.size():
		var best := -INF
		for v in legs[c]:
			best = maxf(best, float(v))
		g.append(best - float(legs[c][i]))
	if u <= times[0]:
		return lerpf(0.0, g[0], u / times[0])
	for c in range(1, times.size()):
		if u <= times[c]:
			var f: float = (u - times[c - 1]) / (times[c] - times[c - 1])
			return lerpf(g[c - 1], g[c], smoothstep(0.0, 1.0, f))
	return g.back()

func _draw_race() -> void:
	var sz := _view.size
	var u := clampf(_t / RACE_SECS, 0.0, 1.0)
	var track_len := 5200.0
	var lead_x := u * track_len + maxf(0.0, _t - RACE_SECS) * 420.0
	var cam := clampf(lead_x - sz.x * 0.68, -60.0, track_len - sz.x * 0.72)
	var horizon := sz.y * 0.34
	# sky and the far side of the course
	_view.draw_rect(Rect2(0, 0, sz.x, horizon), Color("9cc3d8"))
	_view.draw_rect(Rect2(0, horizon * 0.6, sz.x, horizon * 0.4), Color("b9d3df"))
	for k in 9:  # the stands, drifting slowly (far away)
		var sx := fposmod(k * 380.0 - cam * 0.25, sz.x + 380.0) - 190.0
		_view.draw_rect(Rect2(sx, horizon - 56, 240, 56), Color("6a7480"))
		_view.draw_rect(Rect2(sx - 10, horizon - 66, 260, 12), Color("e8e6de"))
		for w in 6:
			_view.draw_rect(Rect2(sx + 12 + w * 38, horizon - 44, 22, 14), Color("3a4250"))
		for d in 40:  # the crowd along the front of the stand
			var hue := fposmod(sin(float(d * 12.9 + k * 78.2)) * 43758.5, 1.0)
			_view.draw_rect(Rect2(sx + 4 + d * 5.8, horizon - 20 - (d % 3) * 2, 4, 7), Color.from_hsv(hue, 0.55, 0.85))
		_view.draw_rect(Rect2(sx + 100, horizon - 96, 3, 30), Color("e8e6de"))
		_view.draw_rect(Rect2(sx + 103, horizon - 96, 18, 11), Color("c8282c") if k % 2 == 0 else Color("2f6a45"))
	_view.draw_rect(Rect2(0, horizon - 8, sz.x, 10), Color("4a6a3a"))
	# the turf, mown in stripes
	_view.draw_rect(Rect2(0, horizon, sz.x, sz.y - horizon), Color("3f7a3a"))
	for k in 30:
		var sx := fposmod(k * 120.0 - cam, 3600.0) - 120.0
		_view.draw_rect(Rect2(sx, horizon, 60, sz.y - horizon), Color(1, 1, 1, 0.04))
	# the far rail
	_view.draw_rect(Rect2(0, horizon + 8, sz.x, 4), Color("f2efe6"))
	# fences or hurdles every so often, running across the track from the far rail to the near one
	if str(_card.kind) != "flat":
		var chase := str(_card.kind) == "chase"
		for fx in range(700, int(track_len) - 300, 900):
			var x := fx - cam
			if x > -120 and x < sz.x + 120:
				var top := horizon + 12
				var bot := sz.y - 26
				var lean := 34.0
				var w := 22.0 if chase else 10.0
				var body := Color("1f3a1c") if chase else Color("8a6a3a")
				_view.draw_colored_polygon(PackedVector2Array([Vector2(x + lean, top), Vector2(x + lean + w, top), Vector2(x + w, bot), Vector2(x, bot)]), body)
				_view.draw_colored_polygon(PackedVector2Array([Vector2(x + lean - 3, top - 6), Vector2(x + lean + w + 3, top - 6), Vector2(x + w + 3, bot - 6), Vector2(x - 3, bot - 6)]), Color(body.lightened(0.45), 0.9))
				if chase:  # the orange take-off board
					_view.draw_colored_polygon(PackedVector2Array([Vector2(x + lean - 8, top), Vector2(x + lean - 3, top), Vector2(x - 3, bot), Vector2(x - 8, bot)]), Color("e07a2a"))
	# the winning post
	var px := track_len - cam
	if px > -40 and px < sz.x + 40:
		_view.draw_rect(Rect2(px, horizon - 40, 8, sz.y - horizon + 30), Color("f2efe6"))
		_view.draw_circle(Vector2(px + 4, horizon - 46), 18, Color("c8282c"))
		_view.draw_circle(Vector2(px + 4, horizon - 46), 12, Color("f2efe6"))
	# the runners, back row first
	var n: int = _card.runners.size()
	var lane_h := (sz.y - horizon - 50) / n
	var anim := int(_t * 8.0) % 2
	for i in n:
		var r: Dictionary = _card.runners[i]
		var x := lead_x - _gap(i, u) * PX_PER_POINT * 1.4 - cam
		var y := horizon + 24 + lane_h * (i + 0.5)
		var bob := absf(sin(_t * 11.0 + i * 1.7)) * 6.0
		var s := clampf(lane_h * 2.6, 72.0, 170.0)
		_view.draw_set_transform(Vector2(x, y + s * 0.42), 0, Vector2(1.0, 0.3))
		_view.draw_circle(Vector2.ZERO, s * 0.35, Color(0, 0, 0, 0.25))
		_view.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var tex: Texture2D = _sprites[r.species][anim]
		_view.draw_texture_rect(tex, Rect2(x - s * 0.5, y - s * 0.55 - bob, s, s), false)
		var cloth := Rect2(x - 15, y + s * 0.12 - bob, 30, 22)
		_draw_silks(_view, cloth, r.silks)
		var f: Font = ThemeDB.fallback_font
		_view.draw_string(f, cloth.position + Vector2(9, 17), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		if bool(r.get("yours", false)) or _slip.any(func(e): return int(e.runner) == i):
			_view.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, y - s * 0.62 - bob), Vector2(x + 8, y - s * 0.62 - bob), Vector2(x, y - s * 0.5 - bob)]), UIKit.GOLD)
	# the near rail, quick in the foreground
	_view.draw_rect(Rect2(0, sz.y - 26, sz.x, 6), Color("f2efe6"))
	for k in 40:
		var sx := fposmod(k * 90.0 - cam * 1.2, 3600.0) - 90.0
		_view.draw_rect(Rect2(sx, sz.y - 26, 6, 26), Color("f2efe6"))
	# the race clock, and the running order as silks, top right
	var f2: Font = load(SERIF)
	_view.draw_string(f2, Vector2(18, 34), "%s  %s" % [_card.time, _card.name], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("1d2230"))
	var now := range(n)
	now.sort_custom(func(a, b): return _gap(a, u) < _gap(b, u))
	var f3: Font = ThemeDB.fallback_font
	for p in now.size():
		var box := Rect2(sz.x - 24 - (n - p) * 34, 14, 28, 24)
		_draw_silks(_view, box, _card.runners[now[p]].silks)
		_view.draw_string(f3, box.position + Vector2(8, 18), str(int(now[p]) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

static func _draw_silks(ci: CanvasItem, r: Rect2, silks: Array) -> void:
	var a := Color(str(silks[0]))
	var b := Color(str(silks[1]))
	ci.draw_rect(r, a)
	match int(silks[2]):
		1:  # hoops
			for k in 3:
				ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * (0.15 + k * 0.3), r.size.x, r.size.y * 0.14), b)
		2:  # stripes
			for k in 3:
				ci.draw_rect(Rect2(r.position.x + r.size.x * (0.12 + k * 0.3), r.position.y, r.size.x * 0.14, r.size.y), b)
		3:  # sash
			ci.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x * 0.3, 0), r.end, r.end - Vector2(r.size.x * 0.3, 0)]), b)
		_:  # plain with a contrasting cap band
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.25)), b)
	ci.draw_rect(r, Color(0, 0, 0, 0.5), false, 1.5)

# ---------------------------------------------------------------- the result

func _finish_race() -> void:
	_phase = "result"
	set_process(false)
	var order: Array = _run.order
	var back := 0
	for e in _slip:
		back += Racing.returns(_card, order, e)
	var lines := []
	if _staked > 0:
		settle(_staked, back, ("You collect %s" % Purse.text(back)) if back > 0 else "Not your race")
	var prize := 0
	if _card.get("novice", false):
		var mine := Racing.yours(_card)
		var place := order.find(mine) + 1
		prize = Racing.novice_prize(place, Game.data.badges.size())
		if prize > 0:
			Purse.pay(Game.data, prize)
			TrainerStats.earned(Game.data, prize)
			if place == 1:
				Punt.note_novice_win(Game.data)
			commit()
			lines.append("%s finished %s: %s in prize money!" % [_card.runners[mine].name, ["first", "second", "third"][place - 1], Purse.text(prize)])
			banner(lines.back(), UIKit.GOLD, 34)
		else:
			lines.append("%s finished %s. They'll learn. They had a lovely time." % [_card.runners[mine].name, _ordinal(place)])
		refresh_header()
	UIKit.clear(_root)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 22)
	_root.add_child(h)
	var res := felt_panel(Color("1d2230f0"), BRASS, 18)
	res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(res)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	res.add_child(col)
	col.add_child(serif(28, UIKit.GOLD, "Result: " + str(_card.name)))
	for p in order.size():
		var i: int = order[p]
		var r: Dictionary = _card.runners[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var pl := serif(24, UIKit.GOLD if p == 0 else UIKit.CREAM, _ordinal(p + 1))
		pl.custom_minimum_size = Vector2(60, 0)
		row.add_child(pl)
		var silk := Control.new()
		silk.custom_minimum_size = Vector2(30, 30)
		silk.draw.connect(func(): _draw_silks(silk, Rect2(0, 3, 28, 24), r.silks))
		row.add_child(silk)
		var nm := UIKit.label(str(r.name) + ("  (yours)" if r.get("yours", false) else ""), 24, UIKit.GOLD if r.get("yours", false) or _slip.any(func(e): return int(e.runner) == i) else UIKit.CREAM)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nm)
		if p > 0:
			row.add_child(UIKit.label(Racing.margin_text(float(_run.perf[order[p - 1]]), float(_run.perf[i])), 18, UIKit.MUTED))
		row.add_child(serif(22, UIKit.MUTED, Odds.text(r.odds)))
		col.add_child(row)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(340, 0)
	side.add_theme_constant_override("separation", 10)
	h.add_child(side)
	if _staked > 0:
		side.add_child(serif(30, UIKit.GOLD if back > 0 else LOSE, "Returns %s" % Purse.text(back)))
		side.add_child(UIKit.label("Staked %s" % Purse.text(_staked), 20, UIKit.MUTED))
	for l in lines:
		var ll := UIKit.label(str(l), 22)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		side.add_child(ll)
	var next: Button
	if _card.get("novice", false):
		next = make_button("Back to the stand", func(): close(null), 340)
		side.add_child(next)
	else:
		next = make_button("On to the next race", _next_race, 340)
		side.add_child(next)
		side.add_child(make_button("Leave", func(): close(null), 340))
	UIKit.focus_later(next)
	set_hints([["confirm", "Choose"], ["cancel", "Leave"]])

func _ordinal(n: int) -> String:
	return ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"][clampi(n - 1, 0, 7)]

func _next_race() -> void:
	_load_card()
	_show_card()

func _on_cancel() -> void:
	if _phase == "race":
		return
	close(null)  # nothing unsettled: a slip that never went off was never staked

func _uses_left_right() -> bool:
	return _phase == "card"
