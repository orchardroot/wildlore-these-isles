class_name BattleMenus
extends Control
## Keyboard, gamepad and mouse pickers for the battle: command, moves, bag, team and the forget-a-move prompt.
## Each picker is awaitable and returns the chosen index (-1 when cancelled). The last cursor position of each
## menu is remembered for the rest of the session (the command menu goes back to Fight each battle).

signal _picked(index: int)
signal cursor_moved(index: int)  # the highlighted row changed (the scene uses it to mark a target)
signal opened(rect: Rect2)  # a picker took this part of the screen (the message box keeps its words clear of it)
signal closed

const CREAM := Color("f2e8cf")
const HEATHER := Color("9b6fb0")
const MUTED := Color("a9a294")

var _active := false
var _rows: Array = []
var _disabled: Array = []
var _cols := 1
var _idx := 0
var _cancel_ok := true
var _footer: Label
var _footer_fn := Callable()
static var _mem := {}  # menu key -> last cursor index; outlives the battle, not the session
var _panel: PanelContainer
var chart_arg := ""  # the creatures in front of you as the type chart's argument ("" = no chart from here); set by the scene each turn
var _footer_panel: PanelContainer  # a picker whose footer sits in a panel of its own (the moves: it takes the message box's place)

## A new battle: keep every remembered cursor except the command menu's, which opens on Fight.
static func new_battle() -> void:
	_mem.erase("command")

static func forget_cursors() -> void:
	_mem.clear()

func remember(key: String, i: int) -> void:
	_mem[key] = i

func recall(key: String) -> int:
	return int(_mem.get(key, 0))

func _ready() -> void:
	new_battle()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("move_up", true) or event.is_action_pressed("ui_up", true):
		_step(0, -1)
	elif event.is_action_pressed("move_down", true) or event.is_action_pressed("ui_down", true):
		_step(0, 1)
	elif event.is_action_pressed("move_left", true) or event.is_action_pressed("ui_left", true):
		_step(-1, 0)
	elif event.is_action_pressed("move_right", true) or event.is_action_pressed("ui_right", true):
		_step(1, 0)
	elif event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		_choose(_idx)
	elif event.is_action_pressed("menu") and chart_arg != "":
		_open_chart.call_deferred()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		if _cancel_ok:
			Audio.sfx("cancel")
			_active = false
			_picked.emit(-1)
	else:
		return
	get_viewport().set_input_as_handled()

## The type chart over the battle, scoped to the creatures in front of you. The picker waits underneath.
func _open_chart() -> void:
	if not _active:
		return
	_active = false
	await Router.open_menu("typechart:" + chart_arg)
	await get_tree().process_frame
	_active = true

func _step(dx: int, dy: int) -> void:
	var n := _rows.size()
	if n == 0:
		return
	var rows := ceili(float(n) / _cols)
	var x := _idx % _cols
	var y := _idx / _cols
	x = posmod(x + dx, _cols) if dx != 0 else x
	y = posmod(y + dy, rows) if dy != 0 else y
	var ni := clampi(y * _cols + x, 0, n - 1)
	if ni != _idx:
		_idx = ni
		Audio.sfx("cursor")
		_highlight()

func _choose(i: int) -> void:
	if i < 0 or i >= _rows.size():
		return
	if _disabled[i]:
		Audio.sfx("deny")
		return
	Audio.sfx("confirm")
	_active = false
	_picked.emit(i)

func _highlight() -> void:
	for i in _rows.size():
		var row: PanelContainer = _rows[i]
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(5)
		sb.set_content_margin_all(5)
		if i == _idx:
			sb.bg_color = Color(HEATHER, 0.45)
			sb.border_color = CREAM
			sb.set_border_width_all(2)
		else:
			sb.bg_color = Color(0, 0, 0, 0)
		row.add_theme_stylebox_override("panel", sb)
		row.modulate = Color(1, 1, 1, 0.45) if _disabled[i] else Color.WHITE
	if _footer and _footer_fn.is_valid():
		_footer.text = _footer_fn.call(_idx)
	cursor_moved.emit(_idx)

## rows: [{"text", "right", "stripe": Color, "chip": String, "chip_colour": Color, "disabled", "sub"}]
func _pick(rect: Rect2, title: String, rows: Array, cols: int, mem_key: String, cancel_ok: bool, footer_fn := Callable(), footer_rect := Rect2()) -> int:
	_clear()
	_cols = cols
	_cancel_ok = cancel_ok
	_footer_fn = footer_fn
	_panel = PanelContainer.new()
	_panel.position = rect.position
	_panel.size = rect.size
	opened.emit(rect)
	var sb: StyleBoxFlat = (load("res://ui/theme.tres") as Theme).get_stylebox("panel", "PanelContainer").duplicate()
	sb.set_content_margin_all(10)
	sb.bg_color.a = 1.0
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_panel.add_child(vb)
	if title != "":
		var t := Label.new()
		t.text = title
		t.add_theme_font_size_override("font_size", 20)
		t.modulate = Color("e8c46a")
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(t)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	_rows = []
	_disabled = []
	for i in rows.size():
		var r := _row(rows[i], i)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(r)
		_rows.append(r)
		_disabled.append(bool(rows[i].get("disabled", false)))
	_footer = null
	if footer_fn.is_valid():
		_footer = Label.new()
		_footer.add_theme_font_size_override("font_size", 19)
		_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_footer.custom_minimum_size = Vector2(0, 26)
		_footer.modulate = Color(1, 1, 1, 0.85)
		if footer_rect.size != Vector2.ZERO:
			_footer.add_theme_font_size_override("font_size", 18)
			_footer.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			_footer_panel = PanelContainer.new()
			_footer_panel.position = footer_rect.position
			_footer_panel.size = footer_rect.size
			_footer_panel.add_theme_stylebox_override("panel", sb)
			var fv := VBoxContainer.new()
			fv.add_child(_footer)
			_footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			if chart_arg != "":
				var hint := Label.new()
				hint.text = "%s: type chart" % UIKit.key_for("menu")
				hint.add_theme_font_size_override("font_size", 16)
				hint.modulate = Color(1, 1, 1, 0.6)
				fv.add_child(hint)
			_footer_panel.add_child(fv)
			add_child(_footer_panel)
		else:
			vb.add_child(_footer)
	_idx = clampi(recall(mem_key), 0, maxi(0, rows.size() - 1))
	if _disabled.size() > 0 and _disabled[_idx]:
		for i in rows.size():
			if not _disabled[i]:
				_idx = i
				break
	_highlight()
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.12)
	if _footer_panel:
		_footer_panel.modulate.a = 0.0
		create_tween().tween_property(_footer_panel, "modulate:a", 1.0, 0.12)
	_active = true
	var r: int = await _picked
	_active = false
	remember(mem_key, _idx)
	_clear()
	return r

func _clear() -> void:
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
		closed.emit()
	_panel = null
	if _footer_panel and is_instance_valid(_footer_panel):
		_footer_panel.queue_free()
	_footer_panel = null
	_rows = []
	_footer = null

func _row(d: Dictionary, i: int) -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _active:
			_idx = i
			_highlight()
			_choose(i))
	row.mouse_entered.connect(func():
		if _active and _idx != i:
			_idx = i
			_highlight())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if d.has("cues") and not d.get("cues_inline", false):  # how the move will land sits on a line of its own under the name
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(v)
		v.add_child(h)
		v.add_child(cue_line(d.cues))
	else:
		row.add_child(h)
	if d.has("stripe"):
		var s := ColorRect.new()
		s.color = d.stripe
		s.custom_minimum_size = Vector2(7, 0)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(s)
	var name_l := Label.new()
	name_l.text = str(d.text)
	name_l.add_theme_font_size_override("font_size", 26)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_l.clip_text = true
	h.add_child(name_l)
	if d.has("chip") and str(d.chip) != "":
		var chip := Label.new()
		chip.text = " %s " % str(d.chip).to_upper()
		chip.add_theme_font_size_override("font_size", 16)
		var chip_fg: Color = d.get("chip_text", Color("14161c"))
		chip.add_theme_color_override("font_color", chip_fg)
		chip.add_theme_constant_override("shadow_offset_x", 0)
		chip.add_theme_constant_override("shadow_offset_y", 0)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = d.get("chip_colour", MUTED)
		sb.set_corner_radius_all(4)
		sb.set_content_margin_all(2)
		if d.has("glyph"):  # type chips carry their shape too, so they never rely on colour alone
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", sb)
			pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var gh := HBoxContainer.new()
			gh.add_theme_constant_override("separation", 0)
			gh.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var gl := TypeGlyph.make(str(d.glyph), chip_fg, 14)
			gh.add_child(gl)
			gh.add_child(chip)
			pc.add_child(gh)
			h.add_child(pc)
		else:
			chip.add_theme_stylebox_override("normal", sb)
			h.add_child(chip)
	if d.get("cues_inline", false):  # the switch menu: how well each member suits this fight, between name and HP
		var cl := cue_line(d.cues)
		cl.custom_minimum_size.x = 250
		h.add_child(cl)
	if d.has("weather"):  # the sky helps (or hinders) this move today
		h.add_child(BattleHUD.WeatherIcon.tag(str(d.weather), int(d.get("weather_dir", 1))))
	if d.has("right") and str(d.right) != "":
		var rl := Label.new()
		rl.text = str(d.right)
		rl.add_theme_font_size_override("font_size", 22)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if d.get("right_warn", false):
			rl.add_theme_color_override("font_color", Color("ff8a7a"))
		h.add_child(rl)
	return row

## The line under a move: shape and words for how it lands, one group per foe when they differ (MoveText.cues).
static func cue_line(cues: Array) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in cues:
		var grp := HBoxContainer.new()
		grp.add_theme_constant_override("separation", 6)
		grp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grp.add_child(EffectMark.make(str(c.kind), 15))
		var l := Label.new()
		var who := str(c.get("who", ""))
		l.text = "%s %s" % [c.words, who] if who != "" else str(c.words)
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", EffectMark.colour_of(str(c.kind)) if str(c.kind) != "even" else MUTED)
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grp.add_child(l)
		line.add_child(grp)
	return line

# --- the pickers ----------------------------------------------------------------

## "fight" | "bag" | "team" | "run"
func command(can_run: bool) -> String:
	var rows := [{"text": "Fight"}, {"text": "Bag"}, {"text": "Team"}, {"text": "Run" if can_run else "Run", "disabled": false}]
	var i := await _pick(Rect2(880, 566, 376, 134), "", rows, 2, "command", false)
	return ["fight", "bag", "team", "run"][maxi(0, i)]

## A plain Yes / No under the message box. Cancel counts as No.
func yes_no() -> bool:
	return await _pick(Rect2(960, 566, 296, 134), "", [{"text": "Yes"}, {"text": "No"}], 2, "yes_no", true) == 0

## After a catch with a full team: 0 to swap with a team member, 1 (or cancel) to send it to the Ark.
func catch_destination() -> int:
	var i := await _pick(Rect2(700, 566, 556, 134), "", [{"text": "Swap with a team member"}, {"text": "Send to the Ark"}], 1, "catch_dest", false)
	return maxi(0, i)

## cue_fn(slot) -> Array: how that move lands on each foe standing (MoveText.cues; [] for a status move).
## weather: the battle's weather, so moves it helps or hinders carry a little sky glyph and arrow.
## chart: with it, the footer adds what the move's type is strong and weak against. Tab (the menu key) opens the
## type chart, scoped to `chart_scope` (see `chart_scope_for`).
func moves(c: Creature, move_db: MoveDB, cue_fn := Callable(), weather := "clear", chart: TypeChart = null) -> int:
	var rows := move_rows(c, move_db, weather, cue_fn)
	var footer := func(i: int) -> String:
		return move_footer(c, i, move_db, "", weather, chart)
	return await _pick(Rect2(470, 540, 786, 164), "", rows, 2, "moves", true, footer, Rect2(24, 524, 436, 176))

static func _all_out_of_pp(c: Creature) -> bool:
	return c.moves.all(func(m): return int(m.pp) <= 0)

## The move picker's rows. A move the weather changes gets "weather" (the kind) and "weather_dir" (1 or -1).
static func move_rows(c: Creature, move_db: MoveDB, weather := "clear", cue_fn := Callable()) -> Array:
	var rows := []
	var all_empty := _all_out_of_pp(c)
	for i in c.moves.size():
		var m: Dictionary = c.moves[i]
		var mv := move_db.get_move(m.id)
		var t := str(mv.get("type", ""))
		var row := {"text": mv.get("name", m.id), "stripe": TypeColours.of(t), "chip": t, "glyph": t, "chip_colour": TypeColours.of(t), "chip_text": TypeColours.text_on(t),
			"right": "%d/%d" % [int(m.pp), int(m.max_pp)], "right_warn": int(m.pp) <= 0, "disabled": int(m.pp) <= 0 and not all_empty}
		var wm := Weather.move_mult(weather, mv)
		if not is_equal_approx(wm, 1.0):
			row["weather"] = weather
			row["weather_dir"] = 1 if wm > 1.0 else -1
		if cue_fn.is_valid():
			var cues: Array = cue_fn.call(i)
			if not cues.is_empty():
				row["cues"] = cues
		rows.append(row)
	return rows

## Two lines under the moves: the numbers (with the type hint up front), then what the move does, led by
## what today's weather does to it when the description doesn't already say.
static func move_footer(c: Creature, i: int, move_db: MoveDB, hint := "", weather := "clear", chart: TypeChart = null) -> String:
	var mv := move_db.get_move(c.moves[i].id)
	if int(c.moves[i].pp) <= 0:
		return "No PP left for that one!" if not _all_out_of_pp(c) else "Out of PP: all that's left is a desperate flail."
	var power := int(mv.get("power", 0))
	var desc := MoveText.describe(mv)
	var tag := Weather.move_tag(weather, mv)
	if tag != "" and not MoveFX.bonus_applies(mv, weather):  # a move's own weather bonus is in its description
		var pct := int(round((Weather.move_mult(weather, mv) - 1.0) * 100.0))
		desc = "%s (%s%d%%). %s" % [tag, "+" if pct > 0 else "-", absi(pct), desc]
	var line := MoveText.matchup_line(mv, chart) if chart != null else ""
	return "%s%s  ·  %s  ·  %s  ·  Accuracy %d\n%s%s" % [(hint.to_upper() + "  ·  ") if hint != "" else "", str(mv.get("type", "")).capitalize(),
		str(mv.get("category", "")).capitalize(), ("Power %d" % power) if power > 0 else "No damage", int(mv.get("accuracy", 100)), desc,
		("\n" + line) if line != "" else ""]

## entries from BattleFlow.battle_items(). Returns the index into entries, or -1.
func bag(entries: Array) -> int:
	if entries.is_empty():
		return -1
	var rows := []
	for e in entries:
		rows.append({"text": e.name, "right": "x%d" % int(e.count)})
	var footer := func(i: int) -> String:
		return bag_footer(entries[i])
	var h := mini(entries.size(), 6) * 46 + 100
	# on the left, over our own creature: both HP plates stay in view while you pick a cup of tea
	return await _pick(Rect2(20, 560 - h, 540, h), "BAG", rows, 1, "bag", true, footer)

## A bag entry's line: a snare leads with its odds, in words, or as a rough number once the species is caught.
static func bag_footer(e: Dictionary) -> String:
	var d := str(e.desc)
	if not e.has("odds"):
		return d
	var odds := MoveText.catch_odds(float(e.odds)) if bool(e.get("known", false)) else MoveText.catch_band(float(e.odds))
	return "%s  ·  %s" % [odds, d]

## mode "switch" (fainted and active are greyed), "forced" (as switch but cannot cancel) or "item" (anyone; revive needs fainted).
## active: the party index out on the field, or an Array of them (double battles).
func party(creatures: Array, active: Variant, mode: String, item: Dictionary = {}, move_db: MoveDB = null, foes := [], chart: TypeChart = null) -> int:
	var out_now: Array = active if active is Array else [active]
	var rows := []
	for i in creatures.size():
		var c: Creature = creatures[i]
		var right := "FNT" if c.is_fainted() else "%d/%d" % [c.hp, c.max_hp()]
		var dis := false
		if mode == "item" or mode == "swap":
			dis = false
		else:
			dis = c.is_fainted() or i in out_now
		var chip := c.status
		if i in out_now and mode != "item" and mode != "swap":
			chip = "out"
		rows.append({"text": "%s  Lv %d" % [c.display_name(), c.level], "right": right, "right_warn": c.is_fainted(),
			"stripe": TypeColours.of(str(c.types()[0])), "chip": chip, "chip_colour": HEATHER if chip == "out" else BattleHUD.STATUS_COLOURS.get(chip, MUTED),
			"chip_text": CREAM if chip == "out" else Color("14161c"), "disabled": dis})
		if (mode == "switch" or mode == "forced") and not dis and move_db != null and chart != null:  # who suits this fight
			var suits := MoveText.suits(c, foes, move_db, chart)
			if not suits.is_empty():
				rows[-1]["cues"] = suits
				rows[-1]["cues_inline"] = true
	var title: String = {"switch": "SEND OUT WHO?", "forced": "SEND OUT WHO?", "item": "USE ON WHOM?", "swap": "SWAP WITH WHO?"}.get(mode, "TEAM")
	var h := creatures.size() * 46 + 56
	return await _pick(Rect2(20, 560 - h, 696, h), title, rows, 1, "party_" + mode, mode != "forced")  # left, as the bag

## Double battles: which foe to aim at. names: the foe at each position ("" for nobody there). Left and right
## match the diorama. Returns the position, or -1 when cancelled.
func target(names: Array) -> int:
	var rows := []
	for i in names.size():
		var n := str(names[i])
		var arrow := "<  " if i == 0 else ""
		var tail := "  >" if i == 1 else ""
		rows.append({"text": arrow + (n if n != "" else "(nobody)") + tail, "disabled": n == ""})
	return await _pick(Rect2(640, 566, 616, 134), "AIM AT WHICH ONE?", rows, 2, "target", true)

## Returns the slot to forget, or -1 to skip learning.
func forget(c: Creature, new_move: String, move_db: MoveDB) -> int:
	var rows := []
	for m in c.moves:
		var mv := move_db.get_move(m.id)
		var t := str(mv.get("type", ""))
		rows.append({"text": mv.get("name", m.id), "stripe": TypeColours.of(t), "chip": t, "glyph": t, "chip_colour": TypeColours.of(t), "chip_text": TypeColours.text_on(t),
			"right": ("Pow %d" % int(mv.get("power", 0))) if int(mv.get("power", 0)) > 0 else "Status"})
	rows.append({"text": "Don't learn it", "stripe": MUTED})
	var nm := move_db.get_move(new_move)
	var title := "%s wants to learn %s (%s). Forget which move?" % [c.display_name(), nm.get("name", new_move), str(nm.get("type", "")).capitalize()]
	var new_line := "Learn %s: %s" % [nm.get("name", new_move), _stats_line(nm)]
	var footer := func(i: int) -> String:
		if i >= c.moves.size():
			return "Keep what you have.\n" + new_line
		var old := move_db.get_move(c.moves[i].id)
		return "Forget %s: %s\n%s" % [old.get("name", c.moves[i].id), _stats_line(old), new_line]
	var r := await _pick(Rect2(470, 250, 786, 420), title, rows, 1, "forget", false, footer)
	return -1 if r >= c.moves.size() else r

## "Power 60, accuracy 95. A physical hit. ..." for the forget-a-move prompt.
static func _stats_line(mv: Dictionary) -> String:
	var power := int(mv.get("power", 0))
	return "%s%s" % [("Power %d. " % power) if power > 0 else "", MoveText.describe(mv)]
