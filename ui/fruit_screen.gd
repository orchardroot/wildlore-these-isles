extends CasinoBase
## "Creature Feature", the Palace's fruit machine (see FruitMachine). Spin, then use any nudges to drop a symbol
## onto the line; a losing spin can light HOLD for the next go. Everything about a spin is fixed (and saved) the
## moment the stake goes in.

const CELL := 92.0
const REEL_W := 128.0
const STOP_TIMES := [0.9, 1.25, 1.6]

var _side: VBoxContainer
var _reels: Control
var _pos := [0, 3, 7]         # stops on the line
var _offset := [0.0, 0.0, 0.0] # drawn position, in stops (fractional while spinning)
var _spinning := false
var _nudges := 0
var _hold_offer := false
var _held := [false, false, false]
var _staked := 0
var _pending := false           # a spin waiting for its nudges to be used
var _icons: Array = []
var _spin_btn: Button
var _collect_btn: Button
var _reel_btns: Array = []      # per reel: [hold, nudge]
var _lamps: Label
var _flash := 0.0

func _build() -> void:
	set_title("Creature Feature")
	stakes = FruitMachine.STAKES
	stake_i = 1
	for s in FruitMachine.SYMBOLS:
		var t := AnimSprite.load_sheet(str(s.species), "icon")
		_icons.append(t)
	for r in 3:
		_offset[r] = float(_pos[r])
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	content.add_child(root)
	# the cabinet
	var cab := felt_panel(Color("4a1620"), BRASS, 18)
	cab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(cab)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8 if not UIKit.big_text() else 2)
	cab.add_child(cv)
	var top := serif(34, UIKit.GOLD, "CREATURE  FEATURE")
	top.add_theme_font_size_override("font_size", 34)  # the cabinet's lettering, part of the machine: one size
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(top)
	_lamps = UIKit.label("", 24, UIKit.CREAM)
	_lamps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(_lamps)
	_reels = Control.new()
	_reels.custom_minimum_size = Vector2(REEL_W * 3 + 60, CELL * 3 + 24)
	_reels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reels.draw.connect(_draw_reels)
	cv.add_child(_reels)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	cv.add_child(row)
	for r in 3:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6 if not UIKit.big_text() else 2)
		var hold := UIKit.pill_button("HOLD", 20)
		hold.custom_minimum_size = Vector2(118, 40)
		hold.pressed.connect(_toggle_hold.bind(r))
		var nudge := UIKit.pill_button("NUDGE", 20)
		nudge.custom_minimum_size = Vector2(118, 40)
		nudge.pressed.connect(_nudge.bind(r))
		col.add_child(hold)
		col.add_child(nudge)
		row.add_child(col)
		_reel_btns.append([hold, nudge])
	# the side: pay table, stake, buttons
	var side := VBoxContainer.new()
	_side = side
	side.custom_minimum_size = Vector2(360, 0)
	side.add_theme_constant_override("separation", 10)
	root.add_child(side)
	var pt := felt_panel(Color("1d2230f0"), Color("5a5f6e"), 12)
	side.add_child(pt)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	pt.add_child(grid)
	for i in range(FruitMachine.SYMBOLS.size() - 1, -1, -1):
		var icons := HBoxContainer.new()
		icons.add_theme_constant_override("separation", 0)
		for k in 3:
			var tr := TextureRect.new()
			tr.texture = _icons[i]
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.custom_minimum_size = Vector2(36, 36)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icons.add_child(tr)
		grid.add_child(icons)
		grid.add_child(serif(24, UIKit.GOLD if i == FruitMachine.SYMBOLS.size() - 1 else UIKit.CREAM, "x %d" % FruitMachine.PAYS[i]))
	var two := HBoxContainer.new()
	for k in 2:
		var tr := TextureRect.new()
		tr.texture = _icons[0]
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(36, 36)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		two.add_child(tr)
	grid.add_child(two)
	grid.add_child(UIKit.label("stake back", 20, UIKit.MUTED))
	var rtp := UIKit.label("Pays about 93p in the pound, played perfectly.", 18, UIKit.MUTED)
	rtp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(rtp)
	side.add_child(stake_picker())
	_spin_btn = make_button("Spin", _spin, 360)
	side.add_child(_spin_btn)
	_collect_btn = make_button("Done nudging", _finish_spin, 360)
	side.add_child(_collect_btn)
	side.add_child(make_button("Step away", func(): _leave(), 360))
	set_hints([["confirm", "Spin"], ["leftright", "Stake"], ["cancel", "Step away"]])
	_update_controls()
	UIKit.focus_later(_spin_btn)

func setup(arg: String) -> void:
	_dev = arg.begins_with("dev")
	if arg == "dev:play":  # screenshots: a hand already under way
		get_tree().create_timer(0.6).timeout.connect(_spin)

func _process(delta: float) -> void:
	_flash += delta
	if _spinning or _pending or _hold_offer:
		_reels.queue_redraw()

func _update_controls() -> void:
	var busy := _spinning
	_spin_btn.disabled = busy or _pending
	if _collect_btn.visible != _pending or not _side.has_meta("sep"):
		_collect_btn.visible = _pending
		fit_side(_side)  # the extra button may need the words a little smaller (Large text)
	for r in 3:
		var hold: Button = _reel_btns[r][0]
		var nudge: Button = _reel_btns[r][1]
		hold.disabled = busy or _pending or not _hold_offer
		hold.text = "HELD" if _held[r] else "HOLD"
		nudge.disabled = busy or not _pending or _nudges <= 0
		for b in [hold, nudge]:
			b.modulate.a = 0.4 if b.disabled else 1.0
	var lamps := []
	if _nudges > 0 and _pending:
		lamps.append("NUDGES  %d" % _nudges)
	if _hold_offer and not _pending:
		lamps.append("HOLDS ON")
	_lamps.text = "   ".join(lamps) if not lamps.is_empty() else " "
	_lamps.add_theme_color_override("font_color", UIKit.GOLD if not lamps.is_empty() else UIKit.MUTED)

func _toggle_hold(r: int) -> void:
	if not _hold_offer or _spinning or _pending:
		return
	var n := _held.count(true)
	if not _held[r] and n >= 2:
		Audio.sfx("bump")
		return  # never all three
	_held[r] = not _held[r]
	Audio.sfx("cursor")
	_update_controls()
	_reels.queue_redraw()

func _spin() -> void:
	if _spinning or _pending:
		return
	var s := stake()
	if why_not(s) != "":
		take_stake(s)  # says why
		return
	Punt.stake(Game.data, s, true)
	_staked = s
	var held: Array = _held.duplicate() if _hold_offer else [false, false, false]
	var res := FruitMachine.spin(Punt.rng(Game.data, "fruit"), _pos, held)
	commit()  # stake gone, spin fixed: saved before a single reel turns
	refresh_header()
	_hold_offer = false
	_held = [false, false, false]
	_spinning = true
	_update_controls()
	await _animate_to(res.pos, held)
	_pos = res.pos
	_spinning = false
	_nudges = int(res.nudges)
	var m := FruitMachine.pays(FruitMachine.line(_pos))
	if m == 0 and _nudges > 0:
		_pending = true
		_hold_offer = bool(res.holds) and not held.has(true)
		Audio.sfx("stat_up")
		_update_controls()
		UIKit.focus_later(_reel_btns[0][1])
		return
	_settle_spin(m, bool(res.holds) and not held.has(true))

func _settle_spin(m: int, holds: bool) -> void:
	_pending = false
	_nudges = 0
	settle(_staked, _staked * m, "" if m <= FruitMachine.TWO_LOW else "x%d!  %s" % [m, Purse.text(_staked * m)])
	_hold_offer = m == 0 and holds
	if _hold_offer:
		Audio.sfx("confirm")
	_update_controls()
	UIKit.focus_later(_spin_btn)

func _nudge(r: int) -> void:
	if not _pending or _nudges <= 0:
		return
	_nudges -= 1
	_pos = FruitMachine.nudge(_pos, r)
	Audio.sfx_at("cursor", 0.0, 0.8)
	var tw := create_tween()
	tw.tween_method(_set_off.bind(r), _offset[r], _offset[r] - 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	_offset[r] = float(_pos[r])
	_update_controls()
	if FruitMachine.pays(FruitMachine.line(_pos)) > 0 or _nudges <= 0:
		_finish_spin()

func _finish_spin() -> void:
	if not _pending:
		return
	var holds := _hold_offer
	_hold_offer = false
	_settle_spin(FruitMachine.pays(FruitMachine.line(_pos)), holds)

## Spins the free reels several turns and lands them on `target`, left to right with a little bounce.
func _animate_to(target: Array, held: Array) -> void:
	var tw := create_tween().set_parallel(true)
	for r in 3:
		if held[r]:
			continue
		var start := float(_offset[r])
		var turns := 3 + r
		var land := float(target[r]) + FruitMachine.STOPS * turns
		while land - start < FruitMachine.STOPS * turns:
			land += FruitMachine.STOPS
		var reel := r
		tw.tween_method(_set_off.bind(reel), start, land, STOP_TIMES[r]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): Audio.sfx_at("cursor", 0.0, 0.7 + 0.15 * reel)).set_delay(STOP_TIMES[r] * 0.85)
	await tw.finished
	for r in 3:
		_offset[r] = float(target[r])
	_reels.queue_redraw()

func _set_off(v: float, r: int) -> void:
	_offset[r] = v
	_reels.queue_redraw()

func _draw_reels() -> void:
	var w := _reels.size.x
	var x0 := (w - REEL_W * 3 - 24) * 0.5
	var top := 12.0
	var line_y := top + CELL * 1.5
	# the reel housing
	var house := Rect2(x0 - 14, top - 10, REEL_W * 3 + 52, CELL * 3 + 20)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("120d0c")
	sb.set_corner_radius_all(12)
	sb.border_color = BRASS
	sb.set_border_width_all(4)
	_reels.draw_style_box(sb, house)
	for r in 3:
		var rx := x0 + r * (REEL_W + 12)
		var rect := Rect2(rx, top, REEL_W, CELL * 3)
		_reels.draw_rect(rect, Color("f6efdc"))
		var off: float = _offset[r]
		var base_i := int(floor(off))
		var frac := off - base_i
		for k in range(-2, 3):
			var stop := base_i + k
			var cy := line_y + (k - frac) * CELL
			if cy < top - CELL * 0.5 or cy > top + CELL * 3.5:
				continue
			var sym := FruitMachine.symbol_at(r, stop)
			var sz := CELL * 0.8
			var dst := Rect2(rx + (REEL_W - sz) * 0.5, cy - sz * 0.5, sz, sz)
			var clip := dst.intersection(rect)
			if clip.size.y <= 1:
				continue
			var tex: Texture2D = _icons[sym]
			var ts := tex.get_size()
			var src := Rect2(0, (clip.position.y - dst.position.y) / sz * ts.y, ts.x, clip.size.y / sz * ts.y)
			var tint := Color.WHITE if not _spinning else Color(1, 1, 1, 0.85)
			_reels.draw_texture_rect_region(tex, Rect2(dst.position.x, clip.position.y, sz, clip.size.y), src, tint)
		# shading top and bottom, like a curved reel
		for b in 6:
			var a := 0.32 * (1.0 - b / 6.0)
			_reels.draw_rect(Rect2(rx, top + b * 8, REEL_W, 8), Color(0, 0, 0, a))
			_reels.draw_rect(Rect2(rx, top + CELL * 3 - (b + 1) * 8, REEL_W, 8), Color(0, 0, 0, a))
		if _held[r] or (_pending and _nudges > 0):
			var glow := 0.5 + 0.5 * sin(_flash * 6.0)
			_reels.draw_rect(rect.grow(3), Color(UIKit.GOLD, 0.5 + 0.4 * glow), false, 3)
	# the win line
	_reels.draw_line(Vector2(x0 - 22, line_y), Vector2(x0 + REEL_W * 3 + 46, line_y), Color(0.85, 0.12, 0.15, 0.85), 3)
	_reels.draw_colored_polygon(PackedVector2Array([Vector2(x0 - 30, line_y - 10), Vector2(x0 - 16, line_y), Vector2(x0 - 30, line_y + 10)]), Color("e8c872"))
	# a sheen across the glass
	_reels.draw_colored_polygon(PackedVector2Array([Vector2(x0 + 70, top), Vector2(x0 + 150, top), Vector2(x0 + 90, top + CELL * 3), Vector2(x0 + 10, top + CELL * 3)]), Color(1, 1, 1, 0.06))

func _leave() -> void:
	if _spinning:
		return
	if _pending:
		_finish_spin()
	close(null)

func _on_cancel() -> void:
	_leave()

func _uses_left_right() -> bool:
	return not _pending
