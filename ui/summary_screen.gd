extends MenuBase
## Summary: front sprite, types, stats, nature, moves with PP and the Creaturepedia fact. Left/right pages through the team;
## up/down picks a move to read what it does. Confirm on a move, then on another, swaps them round.

const STAT_NAMES := {"hp": "HP", "atk": "Attack", "def": "Defence", "lore": "Lore", "ward": "Ward", "spd": "Speed"}

var _index := 0
var _body: HBoxContainer
var _move := 0  # the highlighted move row (kept while paging through the team)
var _move_rows: Array = []
var _move_info: Label
var _moves_of: Creature
var _swap_from := -1  # the move picked to be swapped, or -1
var _genome := false  # the genome page instead of the stats and moves
var _in_ark := false  # summarising the Ark's creatures instead of the team

func _build() -> void:
	set_title("Summary")
	_body = HBoxContainer.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.add_theme_constant_override("separation", 22)
	content.add_child(_body)

## arg: party index ("3"), or "ark:12" for Ark entry 12 (and pages through the Ark).
## A trailing ":swap" opens with the top move already picked to swap (screenshots).
func setup(arg: String) -> void:
	if arg.begins_with("ark:"):
		_in_ark = true
		arg = arg.substr(4)
	var parts := arg.split(":")
	_index = clampi(int(parts[0]), 0, maxi(0, _list().size() - 1))
	if parts.size() > 1 and parts[1] == "genome":  # `--menu=summary:0:genome` (screenshots)
		_genome = true
	if parts.size() > 1 and parts[1] == "swap":
		_swap_from = 0
		_move = 2
	_show()

## Swaps two of a creature's moves (PP and all). Out-of-range slots do nothing.
static func swap_moves(c: Creature, a: int, b: int) -> void:
	var order := MenuLogic.reorder(c.moves, a, b)
	c.moves.clear()
	c.moves.append_array(order)

func _on_cancel() -> void:
	if _swap_from >= 0:
		Audio.sfx("cancel")
		_swap_from = -1
		_set_hint()
		_paint_moves()
		return
	close(null)

## Confirm on a move: pick it, or swap it with the one already picked.
func _move_pressed() -> void:
	if _moves_of == null or _moves_of.moves.size() < 2:
		return
	if _swap_from < 0:
		Audio.sfx("confirm")
		_swap_from = _move
	else:
		Audio.sfx("confirm")
		swap_moves(_moves_of, _swap_from, _move)
		_swap_from = -1
		_show()
		return
	_set_hint()
	_paint_moves()

## Read before the GUI, so the Team screen's focused button underneath never sees these keys.
func _input(event: InputEvent) -> void:
	if _locked or _done:
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if _move_rows.size() > 1:
			_move_pressed()
		return
	var dy := 0
	if event.is_action_pressed("move_up"):
		dy = -1
	elif event.is_action_pressed("move_down"):
		dy = 1
	if dy != 0:
		get_viewport().set_input_as_handled()
		if _move_rows.size() > 1:
			_move = MenuLogic.wrap_index(_move, dy, _move_rows.size())
			Audio.sfx("cursor")
			_paint_moves()
		return
	if event.is_action_pressed("run"):  # Run turns to the genome page and back
		get_viewport().set_input_as_handled()
		_genome = not _genome
		_swap_from = -1
		Audio.sfx("cursor")
		_show()
		return
	var d := 0
	if event.is_action_pressed("move_left"):
		d = -1
	elif event.is_action_pressed("move_right"):
		d = 1
	if d != 0:
		get_viewport().set_input_as_handled()
		if _list().size() > 1:
			_swap_from = -1
			_index = MenuLogic.wrap_index(_index, d, _list().size())
			Audio.sfx("cursor")
			_show()
		return
	super._input(event)

func _list() -> Array:
	return Game.data.ark if _in_ark else party()

func _show() -> void:
	UIKit.clear(_body)
	if _list().is_empty():
		return
	var c: Creature = _list()[_index]
	header_right.text = "%d / %d" % [_index + 1, _list().size()]
	_moves_of = c
	_set_hint()
	_body.add_child(_left(c))
	if _genome:
		_move_rows = []
		_body.add_child(GenomePage.build(Game.data, c))
		return
	_body.add_child(_middle(c))
	_body.add_child(_right(c))

func _set_hint() -> void:
	if _moves_of == null:
		return
	if _swap_from >= 0:
		set_hints([["updown", "Pick a spot"], ["confirm", "Swap here"], ["cancel", "Cancel"]])
		return
	var many := _moves_of.moves.size() > 1 and not _genome
	set_hints(([["updown", "Moves"], ["confirm", "Reorder"]] if many else []) + [["run", "Makings" if not _genome else "Stats"]] + ([["leftright", "Next creature"]] if _list().size() > 1 else []) + [["cancel", "Back"]])

const LEFT_W := 336
const MID_W := 392

func _left(c: Creature) -> Control:
	var p := UIKit.panel(Color("1d2230f0"), 18)
	p.custom_minimum_size = Vector2(LEFT_W, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	# The sprite at full size, in a box trimmed of the frame's empty sky so the rest of the card fits under it.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(288, 262)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var s := AnimSprite.new()
	s.show_species(c.species.id, "front", 3, false, c.variant, c.form, c.sex)
	s.position = Vector2(0, -18)
	holder.add_child(s)
	v.add_child(holder)
	var inner := LEFT_W - 36
	var n := UIKit.fit_label(c.display_name(), inner, 38, 24)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	if c.nickname != "" and c.nickname != c.species.name:
		var sp := UIKit.label(c.species.name, 22, UIKit.MUTED)
		sp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sp)
	if Sexes.valid(c.sex):  # page one says it plainly: the sign and the word
		var sx_row := HBoxContainer.new()
		sx_row.alignment = BoxContainer.ALIGNMENT_CENTER
		sx_row.add_theme_constant_override("separation", 8)
		sx_row.add_child(UIKit.sex_mark(c, 26))
		sx_row.add_child(UIKit.label(UIKit.sex_word(c), 24, Sexes.colour(c.sex)))
		v.add_child(sx_row)
	var lv_row := HBoxContainer.new()  # "Level 12", with a single type beside it
	lv_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lv_row.add_theme_constant_override("separation", 14)
	lv_row.add_child(UIKit.label("Level %d" % c.level, 30, UIKit.GOLD))
	v.add_child(lv_row)
	var tags := HFlowContainer.new()  # two types, an uncommon coat, fainted or a status: one line, two at a pinch
	tags.alignment = FlowContainer.ALIGNMENT_CENTER
	tags.add_theme_constant_override("h_separation", 8)
	tags.add_theme_constant_override("v_separation", 6)
	for t in c.types():
		var chip := UIKit.type_chip(str(t), 20)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		(lv_row if c.types().size() == 1 else tags).add_child(chip)
	if c.form != "":
		tags.add_child(UIKit.chip(Forms.name_of(str(c.species.id), c.form) + " form", Color("3a4a3a"), Color("dfe8d0"), 20))
	if c.variant != "":
		tags.add_child(CoatArt.coat_chip(c.variant))
	var st: Control = UIKit.chip("fainted", Color("6b2f2f")) if c.is_fainted() else UIKit.status_chip(c.status, 20)
	if st:
		tags.add_child(st)
	if tags.get_child_count() > 0:
		v.add_child(tags)
	else:
		tags.free()
	v.add_child(UIKit.fill())
	v.add_child(_xp_box(c))
	var evo: String = preload("res://ui/pedia_screen.gd").evolution_line(c.species)
	if evo != "":
		var el := UIKit.label(evo, 19, UIKit.GOLD)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(el)
	return p

## XP: a thin bar through this level, and how far to the next.
func _xp_box(c: Creature) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	var maxed := c.level >= Rules.MAX_LEVEL
	var from := Rules.xp_for_level(c.species.growth, c.level)
	var nxt := Rules.xp_for_level(c.species.growth, c.level + 1) if not maxed else c.xp
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = maxi(1, nxt - from)
	bar.value = clampi(c.xp - from, 0, maxi(1, nxt - from)) if not maxed else bar.max_value
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", UIKit.box(Color("0d0f15"), Color("4a4f5e"), 1, 3, 0))
	bar.add_theme_stylebox_override("fill", UIKit.box(Color("6fa8dc"), Color(0, 0, 0, 0), 0, 3, 0))
	v.add_child(bar)
	var t := "XP %d  ·  %d to Lv %d" % [c.xp, maxi(0, nxt - c.xp), c.level + 1] if not maxed else "XP %d  ·  maxed out" % c.xp
	var xl := UIKit.label(t, 18, UIKit.MUTED)
	xl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(xl)
	return v

## 2.0: the line's knack (a passive that works in battle), at the top of the about panel.
func _knack_box(c: Creature) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var kid := Knacks.id_of(c)
	if kid == "":
		return v
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UIKit.label("Knack", 20, UIKit.MUTED))
	row.add_child(UIKit.label(Knacks.name_of(kid), 20, UIKit.GOLD))
	v.add_child(row)
	var d := UIKit.label(Knacks.desc_of(kid), 17, Color("d8cfb4"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return v

## Friendship (hearts and what they do for you) and the charm it is holding, under the stats.
func _bond_box(c: Creature) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(UIKit.label("Friendship", 22, UIKit.MUTED))
	var hr := BondIcons.hearts_row(c.friendship, 20)
	hr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(hr)
	v.add_child(top)
	v.add_child(_small(Bond.perk_line(c), UIKit.MUTED))
	if c.held != "":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var tok := BondIcons.Token.new(16)
		tok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tok)
		var nm := UIKit.label("%s:" % Charms.name_of(c.held), 16, UIKit.GOLD)
		row.add_child(nm)
		var fx := UIKit.label(str(Charms.item(c.held).get("effect_text", "")), 16, Color("d8cfb4"))
		fx.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		fx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fx.clip_text = true
		row.add_child(fx)
		row.custom_minimum_size = Vector2(340, 0)
		v.add_child(UIKit.spacer(4))
		v.add_child(row)
	return v

## A small wrapped line that wraps inside the stats panel instead of widening it.
func _small(text: String, colour: Color, size := 16) -> Label:
	var l := UIKit.label(text, size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(340, 0)
	return l

func _middle(c: Creature) -> Control:
	var p := UIKit.panel(Color("1d2230f0"), 18)
	p.custom_minimum_size = Vector2(MID_W, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	p.add_child(v)
	v.add_child(UIKit.label("Stats", 24, UIKit.MUTED))
	var nat: Array = Rules.NATURES.get(c.nature, [])
	for s in Rules.STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var tag := ""
		var colour := UIKit.CREAM
		if nat.size() == 2 and nat[0] == s:
			tag = "+"
			colour = Color("8fd48f")
		elif nat.size() == 2 and nat[1] == s:
			tag = "-"
			colour = Color("e9998c")
		var name_l := UIKit.label(STAT_NAMES[s] + tag, 24, colour)
		name_l.custom_minimum_size = Vector2(118, 0)
		row.add_child(name_l)
		var val := c.max_hp() if s == "hp" else c.calc_stat(s)
		# HP reads "22 / 33", so its bar is the health bar (current over max); the others show the stat's size
		var bar: ProgressBar
		if s == "hp":
			bar = UIKit.hp_bar(c.hp, val, 124, 14)
		else:
			bar = ProgressBar.new()
			bar.show_percentage = false
			bar.max_value = 130
			bar.value = val
			bar.custom_minimum_size = Vector2(124, 14)
			bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.HEATHER, Color(0, 0, 0, 0), 0, 3, 0))
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		var txt := "%d / %d" % [c.hp, val] if s == "hp" else str(val)
		var vl := UIKit.label(txt, 24)
		vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(vl)
		v.add_child(row)
	v.add_child(UIKit.spacer(6))
	var nl := UIKit.label("%s temper" % c.nature.capitalize(), 26, UIKit.GOLD)
	v.add_child(nl)
	if nat.size() == 2:
		v.add_child(UIKit.label("Likes %s, less keen on %s" % [STAT_NAMES[nat[0]], STAT_NAMES[nat[1]]], 20, UIKit.MUTED))
	else:
		v.add_child(_small("Perfectly balanced, as all things should be", UIKit.MUTED, 18))
	v.add_child(_bond_box(c))
	return p

func _right(c: Creature) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	var mp := UIKit.panel(Color("1d2230f0"), 14)
	col.add_child(mp)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 2)
	mp.add_child(mv)
	_moves_of = c
	_move_rows = []
	for i in c.moves.size():
		var m: Dictionary = c.moves[i]
		var info: Dictionary = Game.moves.get_move(m.id)
		var hl := PanelContainer.new()
		hl.mouse_filter = Control.MOUSE_FILTER_STOP
		hl.mouse_entered.connect(func():
			if _move != i:
				_move = i
				_paint_moves())
		hl.gui_input.connect(func(ev: InputEvent):
			var mb := ev as InputEventMouseButton
			if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not _locked and not _done:
				_move = i
				_move_pressed())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip := UIKit.type_chip(str(info.get("type", "kin")), 16)
		chip.custom_minimum_size = Vector2(112, 0)  # wide enough for HEDGEROW, so the names line up
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(chip)
		var mn := UIKit.label(str(info.get("name", m.id)), 24)
		mn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mn.clip_text = true  # a long move name trims rather than push the PP off the panel
		mn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(mn)
		var low: bool = int(m.pp) * 4 <= int(m.max_pp)
		row.add_child(UIKit.label("PP %d/%d" % [m.pp, m.max_pp], 20, Color("e9998c") if low else UIKit.MUTED))
		for k in row.get_children():
			k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hl.add_child(row)
		mv.add_child(hl)
		_move_rows.append(hl)
	for i in range(c.moves.size(), 4):
		mv.add_child(UIKit.label("-", 26, UIKit.MUTED))
	_move_info = UIKit.label("", 18, Color("d8cfb4"))
	_move_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_move_info.custom_minimum_size = Vector2(0, 50)  # two lines, so paging moves never shifts the layout
	mv.add_child(_move_info)
	_move = clampi(_move, 0, maxi(0, c.moves.size() - 1))
	_paint_moves()
	var fp := UIKit.panel(Color("1d2230f0"), 16)
	fp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fp)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 10)
	fp.add_child(fv)
	var kb := _knack_box(c)
	if kb.get_child_count() > 0:
		fv.add_child(kb)
		var rule := ColorRect.new()
		rule.color = Color(UIKit.CREAM, 0.15)
		rule.custom_minimum_size = Vector2(0, 2)
		fv.add_child(rule)
	else:
		kb.free()
	var dex: Dictionary = c.species.get("dex", {})
	var wb := UIKit.words_box([21, 19, 18, 17, 16], 6)  # long entries step the type down so it never spills
	fv.add_child(wb[0])
	UIKit.add_words(wb[1], str(dex.get("text", "")))
	UIKit.add_words(wb[1], "Did you know?", 1, UIKit.GOLD, true)  # the Fieldbook always has room for the fact
	UIKit.add_words(wb[1], str(dex.get("fact", "")), 0, Color("d8cfb4"), true)
	return col

## Highlights the chosen move row and says what that move does.
func _paint_moves() -> void:
	for i in _move_rows.size():
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(5)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		sb.bg_color = Color(UIKit.HEATHER, 0.35) if i == _move else Color(0, 0, 0, 0)
		if i == _swap_from:
			sb.bg_color = Color(UIKit.GOLD, 0.30)
			sb.border_color = UIKit.GOLD
			sb.set_border_width_all(2)
		_move_rows[i].add_theme_stylebox_override("panel", sb)
	if _move_info == null or _moves_of == null or _move >= _moves_of.moves.size():
		return
	var info: Dictionary = Game.moves.get_move(_moves_of.moves[_move].id)
	var power := int(info.get("power", 0))
	if _swap_from >= 0:
		var from_name := str(Game.moves.get_move(_moves_of.moves[_swap_from].id).get("name", ""))
		_move_info.text = "Swap %s with %s?" % [from_name, info.get("name", "")] if _swap_from != _move else "Pick where %s should go." % from_name
		return
	_move_info.text = "%sAccuracy %d  ·  %s" % [("Power %d  ·  " % power) if power > 0 else "", int(info.get("accuracy", 100)), MoveText.describe(info)]
